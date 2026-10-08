/// Fail-closed privacy health review for roadmap step 118.19.
///
/// The delayed release path has no live telemetry to inspect. This gate therefore
/// freezes the privacy controls that would govern observation and refuses to
/// describe a local fixture as a production reading.
library;

import 'dart:convert';
import 'dart:io';

enum Sprint118PrivacyHealthState { pass, fail, blocked }

class Sprint118PrivacyHealthEntry {
  const Sprint118PrivacyHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.destination,
    required this.retentionDays,
    required this.limitations,
    this.consentExplicit = true,
    this.deletionSupported = true,
    this.disconnectSupported = true,
    this.telemetryDisabled = true,
    this.metadataMinimized = true,
    this.transferExplicit = true,
    this.observed = false,
  });

  final String signal;
  final String referenceState;
  final String source;
  final String destination;
  final int retentionDays;
  final List<String> limitations;
  final bool consentExplicit;
  final bool deletionSupported;
  final bool disconnectSupported;
  final bool telemetryDisabled;
  final bool metadataMinimized;
  final bool transferExplicit;
  final bool observed;
}

class Sprint118PrivacyHealthReview {
  const Sprint118PrivacyHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118PrivacyHealthEntry> entries;

  List<String> get signals => <String>[for (final e in entries) e.signal];
  int get observedCount => entries.where((e) => e.observed).length;
}

class Sprint118PrivacyHealthAnchor {
  const Sprint118PrivacyHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.observationState,
    required this.observationVerdict,
    required this.observationReleaseState,
    required this.observationAcceptance,
    required this.complianceStatus,
    required this.dataFlowOutputs,
    required this.monitoringSignals,
    required this.collectionOff,
    required this.consentGate,
    required this.telemetryExecuted,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;
  final String observationState;
  final String observationVerdict;
  final String observationReleaseState;
  final List<String> observationAcceptance;
  final String complianceStatus;
  final List<String> dataFlowOutputs;
  final List<String> monitoringSignals;
  final bool collectionOff;
  final String consentGate;
  final bool telemetryExecuted;
  final List<String> readableSources;
}

class Sprint118PrivacyHealthReport {
  const Sprint118PrivacyHealthReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredSignals = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118PrivacyHealthState state;
  final String verdict;
  final String releaseState;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredSignals;
  final int observedCount;

  bool get reviewVerified => state == Sprint118PrivacyHealthState.pass;
}

abstract final class Sprint118PrivacyHealthContract {
  const Sprint118PrivacyHealthContract._();

  static const canonicalStep = '118.19';
  static const title = 'Privacy Health Review';
  static const manifestPath =
      'docs/planning/v1.3/sprint_118_privacy_health_review.json';
  static const ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';
  static const baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';
  static const charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';
  static const observationManifestPath =
      'docs/planning/v1.3/sprint_118_privacy_safe_observation.json';
  static const complianceManifestPath =
      'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json';
  static const dataFlowManifestPath =
      'docs/planning/v1.2/sprint_115_privacy_data_flow_review.json';
  static const monitoringManifestPath =
      'docs/planning/v1.3/sprint_117_privacy_safe_monitoring.json';

  static const delayedReleaseState = 'GA_DELAYED';
  static const requiredBaselineState = 'pass';
  static const requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const requiredCharterState = 'pass';
  static const requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const requiredObservationState = 'pass';
  static const requiredObservationVerdict =
      'PRIVACY_SAFE_OBSERVATION_VERIFIED_LOCAL';
  static const requiredConsentGate = 'opt-in default OFF';
  static const maxRetentionDays = 30;

  static const requiredFields = <String>[
    'signal',
    'destination',
    'consent',
    'retention',
    'deletion',
    'disconnect',
    'telemetry',
    'metadata',
    'transfer',
  ];

  static const privacySignals = <String>[
    'consent_issue',
    'destination_issue',
    'retention_issue',
    'deletion_issue',
    'disconnect_issue',
    'telemetry_issue',
    'metadata_issue',
    'transfer_issue',
  ];

  static const canonicalSources = <String>[
    observationManifestPath,
    complianceManifestPath,
    complianceManifestPath,
    complianceManifestPath,
    complianceManifestPath,
    observationManifestPath,
    observationManifestPath,
    dataFlowManifestPath,
  ];

  static const externalGates = 'DEFERRED-EXTERNAL';

  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final value in vocabulary) {
        if (seen.add(value)) result.add(value);
      }
    }
    return result;
  }

  static String sourceFor(String signal) {
    final index = privacySignals.indexOf(signal);
    return index < 0 ? '' : canonicalSources[index];
  }

  static const canonicalReview = Sprint118PrivacyHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118PrivacyHealthEntry>[
      Sprint118PrivacyHealthEntry(
        signal: 'consent_issue',
        referenceState: 'consent',
        source: observationManifestPath,
        destination: 'local opt-in consent gate',
        retentionDays: maxRetentionDays,
        limitations: <String>['live_observation_deferred', 'synthetic_local'],
      ),
      Sprint118PrivacyHealthEntry(
        signal: 'destination_issue',
        referenceState: 'destinations',
        source: complianceManifestPath,
        destination: 'declared provider destinations only',
        retentionDays: maxRetentionDays,
        limitations: <String>['provider_transfer_deferred', 'synthetic_local'],
      ),
      Sprint118PrivacyHealthEntry(
        signal: 'retention_issue',
        referenceState: 'retention',
        source: complianceManifestPath,
        destination: 'local retention policy',
        retentionDays: maxRetentionDays,
        limitations: <String>['live_observation_deferred', 'synthetic_local'],
      ),
      Sprint118PrivacyHealthEntry(
        signal: 'deletion_issue',
        referenceState: 'deletion',
        source: complianceManifestPath,
        destination: 'local deletion and backup boundary',
        retentionDays: maxRetentionDays,
        limitations: <String>[
          'real_subject_request_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118PrivacyHealthEntry(
        signal: 'disconnect_issue',
        referenceState: 'disconnect',
        source: complianceManifestPath,
        destination: 'local disconnect cleanup contract',
        retentionDays: maxRetentionDays,
        limitations: <String>[
          'live_provider_revoke_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118PrivacyHealthEntry(
        signal: 'telemetry_issue',
        referenceState: 'disable_control',
        source: observationManifestPath,
        destination: 'local opt-in telemetry control',
        retentionDays: maxRetentionDays,
        limitations: <String>[
          'production_telemetry_deferred',
          'synthetic_local',
        ],
      ),
      Sprint118PrivacyHealthEntry(
        signal: 'metadata_issue',
        referenceState: 'minimization',
        source: observationManifestPath,
        destination: 'aggregate metadata only',
        retentionDays: maxRetentionDays,
        limitations: <String>['live_observation_deferred', 'synthetic_local'],
      ),
      Sprint118PrivacyHealthEntry(
        signal: 'transfer_issue',
        referenceState: 'external_transfer',
        source: dataFlowManifestPath,
        destination: 'explicit workspace/provider transfer boundary',
        retentionDays: maxRetentionDays,
        limitations: <String>['connector_transfer_deferred', 'synthetic_local'],
      ),
    ],
  );
}

class Sprint118PrivacyHealthLoader {
  const Sprint118PrivacyHealthLoader();

  Sprint118PrivacyHealthAnchor? loadAnchor() {
    final baseline = _read(Sprint118PrivacyHealthContract.baselineManifestPath);
    final charter = _read(Sprint118PrivacyHealthContract.charterManifestPath);
    final observation = _read(
      Sprint118PrivacyHealthContract.observationManifestPath,
    );
    final compliance = _read(
      Sprint118PrivacyHealthContract.complianceManifestPath,
    );
    final dataFlow = _read(Sprint118PrivacyHealthContract.dataFlowManifestPath);
    final monitoring = _read(
      Sprint118PrivacyHealthContract.monitoringManifestPath,
    );
    if ([
      baseline,
      charter,
      observation,
      compliance,
      dataFlow,
      monitoring,
    ].any((value) => value == null)) {
      return null;
    }
    final window = charter!['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final sources = <String>{
      Sprint118PrivacyHealthContract.baselineManifestPath,
      Sprint118PrivacyHealthContract.charterManifestPath,
      Sprint118PrivacyHealthContract.observationManifestPath,
      Sprint118PrivacyHealthContract.complianceManifestPath,
      Sprint118PrivacyHealthContract.dataFlowManifestPath,
      Sprint118PrivacyHealthContract.monitoringManifestPath,
    };
    final dataFlowSources = dataFlow!['sources'];
    final dataFlowCanonical = dataFlowSources is Map<String, dynamic>
        ? dataFlowSources['canonical_steps']
        : null;
    final dataFlowCanonicalMap = dataFlowCanonical is Map<String, dynamic>
        ? dataFlowCanonical
        : const <String, dynamic>{};
    return Sprint118PrivacyHealthAnchor(
      baselineState: _text(baseline!['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: durationDays > 0 ? durationDays * 24 * 60 : 0,
      observationState: _text(observation!['state']),
      observationVerdict: _text(observation['verdict']),
      observationReleaseState: _text(observation['release_state']),
      observationAcceptance: _strings(observation['acceptance_fields']),
      complianceStatus: _text(compliance!['status']),
      dataFlowOutputs: _strings(dataFlowCanonicalMap['required_outputs']),
      monitoringSignals: _strings(monitoring!['required_signals']),
      collectionOff:
          observation['default_collection'] == false &&
          monitoring['default_collection'] == false,
      consentGate: _text(observation['consent_gate']),
      telemetryExecuted:
          observation['telemetry_executed'] == true ||
          monitoring['telemetry_executed'] == true,
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

  static int _int(Object? value) => value is int ? value : 0;
}

class Sprint118PrivacyHealthGate {
  const Sprint118PrivacyHealthGate();

  Sprint118PrivacyHealthReport evaluate() {
    final anchor = const Sprint118PrivacyHealthLoader().loadAnchor();
    if (anchor == null) {
      return const Sprint118PrivacyHealthReport(
        state: Sprint118PrivacyHealthState.blocked,
        verdict: 'SPRINT_118_PRIVACY_HEALTH_BLOCKED_UPSTREAM',
        releaseState: '',
        blockers: <String>['privacy_witness_unreadable'],
      );
    }
    return evaluateWith(anchor, Sprint118PrivacyHealthContract.canonicalReview);
  }

  Sprint118PrivacyHealthReport evaluateWith(
    Sprint118PrivacyHealthAnchor anchor,
    Sprint118PrivacyHealthReview review,
  ) {
    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];
    final vocabulary = Sprint118PrivacyHealthContract.stateVocabulary(
      <List<String>>[
        anchor.observationAcceptance,
        anchor.dataFlowOutputs,
        anchor.monitoringSignals,
        <String>[
          'data_flow',
          'consent',
          'minimization',
          'destinations',
          'retention',
          'deletion',
          'disconnect',
          'external_transfer',
        ],
      ],
    );

    if (anchor.baselineState !=
            Sprint118PrivacyHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118PrivacyHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen');
    }
    if (anchor.charterState !=
            Sprint118PrivacyHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118PrivacyHealthContract.requiredCharterVerdict ||
        anchor.charterWindowMinutes <= 0) {
      blockers.add('charter_not_complete');
    }
    if (anchor.observationState !=
            Sprint118PrivacyHealthContract.requiredObservationState ||
        anchor.observationVerdict !=
            Sprint118PrivacyHealthContract.requiredObservationVerdict ||
        anchor.observationReleaseState !=
            Sprint118PrivacyHealthContract.delayedReleaseState) {
      blockers.add('privacy_observation_not_verified');
    }
    if (anchor.complianceStatus != 'VERIFIED-LOCAL') {
      blockers.add('privacy_compliance_not_verified');
    }
    if (anchor.releaseState !=
            Sprint118PrivacyHealthContract.delayedReleaseState ||
        review.releaseState != anchor.releaseState) {
      violations.add('release_state_mismatch');
    }
    if (anchor.consentGate !=
            Sprint118PrivacyHealthContract.requiredConsentGate ||
        !anchor.collectionOff) {
      violations.add('consent_default_not_opt_in_off');
    }
    if (anchor.telemetryExecuted) {
      violations.add('telemetry_claimed_executed_on_delayed_path');
    }
    if (anchor.observationAcceptance.isEmpty ||
        anchor.dataFlowOutputs.isEmpty ||
        anchor.monitoringSignals.isEmpty) {
      blockers.add('privacy_vocabulary_missing');
    }

    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
      if (!Sprint118PrivacyHealthContract.privacySignals.contains(
        entry.signal,
      )) {
        violations.add('signal_unknown:${entry.signal}');
      }
      if (entry.referenceState.trim().isEmpty ||
          !vocabulary.contains(entry.referenceState)) {
        violations.add('reference_state_invalid:${entry.signal}');
      }
      if (entry.source.trim().isEmpty ||
          !anchor.readableSources.contains(entry.source)) {
        violations.add('source_unreadable:${entry.signal}');
      }
      if (entry.destination.trim().isEmpty) {
        violations.add('destination_missing:${entry.signal}');
      }
      if (entry.retentionDays <= 0 ||
          entry.retentionDays >
              Sprint118PrivacyHealthContract.maxRetentionDays) {
        violations.add('retention_out_of_bounds:${entry.signal}');
      }
      if (entry.limitations.isEmpty) {
        violations.add('limitations_missing:${entry.signal}');
      }
      if (!entry.consentExplicit) {
        violations.add('consent_missing:${entry.signal}');
      }
      if (!entry.deletionSupported) {
        violations.add('deletion_missing:${entry.signal}');
      }
      if (!entry.disconnectSupported) {
        violations.add('disconnect_missing:${entry.signal}');
      }
      if (!entry.telemetryDisabled) {
        violations.add('telemetry_control_missing:${entry.signal}');
      }
      if (!entry.metadataMinimized) {
        violations.add('metadata_not_minimized:${entry.signal}');
      }
      if (!entry.transferExplicit) {
        violations.add('transfer_not_explicit:${entry.signal}');
      }
      if (entry.observed) {
        violations.add('live_observation_claimed:${entry.signal}');
      }
    }
    for (final signal in declared.keys) {
      if (declared[signal]! > 1) {
        violations.add('signal_duplicate:$signal');
      }
    }
    for (final signal in Sprint118PrivacyHealthContract.privacySignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }
    for (final source in <String>[
      Sprint118PrivacyHealthContract.baselineManifestPath,
      Sprint118PrivacyHealthContract.charterManifestPath,
      Sprint118PrivacyHealthContract.observationManifestPath,
      Sprint118PrivacyHealthContract.complianceManifestPath,
      Sprint118PrivacyHealthContract.dataFlowManifestPath,
      Sprint118PrivacyHealthContract.monitoringManifestPath,
    ]) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('required_source_unreadable:$source');
      }
    }

    final allItems = <String>[...violations, ...blockers, ...openItems];
    if (violations.isNotEmpty) {
      return Sprint118PrivacyHealthReport(
        state: Sprint118PrivacyHealthState.fail,
        verdict: 'SPRINT_118_PRIVACY_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredSignals: review.signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118PrivacyHealthReport(
        state: Sprint118PrivacyHealthState.blocked,
        verdict: 'SPRINT_118_PRIVACY_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allItems,
        declaredSignals: review.signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118PrivacyHealthReport(
      state: Sprint118PrivacyHealthState.pass,
      verdict: 'PRIVACY_HEALTH_REVIEW_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allItems,
      declaredSignals: review.signals,
      observedCount: review.observedCount,
    );
  }
}
