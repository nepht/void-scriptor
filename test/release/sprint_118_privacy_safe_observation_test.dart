import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_privacy_safe_observation.dart';

/// A single observation signal. Each test flips exactly the one thing it is
/// about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ObservationSignal _signal({
  String signal = 'connection_outcome',
  List<String>? collectedFields,
  bool requiresExplicitConsent = true,
  bool minimized = true,
  int retentionDays = 30,
  bool disableControl = true,
}) {
  return Sprint118ObservationSignal(
    signal: signal,
    collectedFields:
        collectedFields ?? const <String>['connection_state', 'health_state'],
    requiresExplicitConsent: requiresExplicitConsent,
    minimized: minimized,
    retentionDays: retentionDays,
    disableControl: disableControl,
  );
}

Sprint118PrivacyObservation _observation({
  String releaseState = Sprint118PrivacyObservationContract.delayedReleaseState,
  bool defaultCollection = false,
  List<Sprint118ObservationSignal>? signals,
}) {
  return Sprint118PrivacyObservation(
    releaseState: releaseState,
    defaultCollection: defaultCollection,
    signals:
        signals ??
        Sprint118PrivacyObservationContract.canonicalObservation.signals,
  );
}

/// The canonical signals with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole plan.
List<Sprint118ObservationSignal> _replacing(
  String signal,
  Sprint118ObservationSignal replacement,
) {
  return <Sprint118ObservationSignal>[
    for (final s
        in Sprint118PrivacyObservationContract.canonicalObservation.signals)
      if (s.signal == signal) replacement else s,
  ];
}

Sprint118PrivacyObservationAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118PrivacyObservationContract.requiredBaselineVerdict,
  String releaseState = Sprint118PrivacyObservationContract.delayedReleaseState,
  String consentGate = Sprint118PrivacyObservationContract.requiredConsentGate,
  bool defaultCollection = false,
  bool telemetryExecuted = false,
  List<String>? excludedCategories,
  List<String>? readableSources,
}) {
  return Sprint118PrivacyObservationAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    consentGate: consentGate,
    defaultCollection: defaultCollection,
    telemetryExecuted: telemetryExecuted,
    excludedCategories:
        excludedCategories ??
        const <String>[
          'manuscript',
          'novel',
          'chapter',
          'scene',
          'character',
          'lore',
          'worldbuilding',
          'prompt',
          'draft',
          'outline',
          'creative',
          'credential',
          'password',
          'secret',
          'token',
          'api_key',
          'screenshot',
          'recording',
          'email_address',
        ],
    readableSources:
        readableSources ?? Sprint118PrivacyObservationContract.canonicalSources,
  );
}

Sprint118PrivacyObservationReport _run(
  Sprint118PrivacyObservation observation, {
  Sprint118PrivacyObservationAnchor? anchor,
}) {
  return const Sprint118PrivacyObservationGate().evaluateWith(
    anchor ?? _anchor(),
    observation,
  );
}

void main() {
  group('118.5 Privacy-Safe Observation Verification', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118PrivacyObservationContract.canonicalStep, '118.5');
      expect(
        Sprint118PrivacyObservationContract.title,
        'Privacy-Safe Observation Verification',
      );
      expect(
        Sprint118PrivacyObservationContract.manifestPath,
        'docs/planning/v1.3/sprint_118_privacy_safe_observation.json',
      );
      expect(Sprint118PrivacyObservationContract.acceptanceFields, <String>[
        'creative_content_excluded',
        'secrets_excluded',
        'raw_payment_excluded',
        'consent',
        'minimization',
        'retention',
        'disable_control',
      ]);
      expect(
        Sprint118PrivacyObservationContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118PrivacyObservationContract.acceptanceFields.length, 7);
      expect(Sprint118PrivacyObservationContract.creativeTerms, isNotEmpty);
      expect(Sprint118PrivacyObservationContract.secretTerms, isNotEmpty);
      expect(Sprint118PrivacyObservationContract.rawPaymentTerms, isNotEmpty);
      // The objective names media and raw payment explicitly; both must be
      // owned by the 118.5 vocabulary even though the upstream witness omits
      // them.
      expect(
        Sprint118PrivacyObservationContract.excludedVocabulary,
        containsAll(<String>['media', 'payment']),
      );
      expect(Sprint118PrivacyObservationContract.maxRetentionDays, 30);
    });

    test('canonical observation covers the seven signals and collects nothing '
        'excluded', () {
      final signals =
          Sprint118PrivacyObservationContract.canonicalObservation.signalIds;
      expect(signals.length, 7);
      expect(signals.toSet(), <String>{
        'connection_outcome',
        'quota_refresh',
        'sync_outcome',
        'provider_error',
        'usage_metadata',
        'billing_state',
        'workflow_completion',
      });
      for (final signal
          in Sprint118PrivacyObservationContract.canonicalObservation.signals) {
        expect(signal.requiresExplicitConsent, isTrue);
        expect(signal.minimized, isTrue);
        expect(signal.disableControl, isTrue);
        expect(signal.retentionDays, greaterThan(0));
        for (final field in signal.collectedFields) {
          expect(
            Sprint118PrivacyObservationContract.fieldCategory(field),
            isNull,
            reason: '$field must not be an excluded category',
          );
        }
      }
    });

    test('passes on the canonical observation', () {
      final report = _run(_observation());
      expect(report.state, Sprint118PrivacyState.pass);
      expect(report.verdict, 'PRIVACY_SAFE_OBSERVATION_VERIFIED_LOCAL');
      expect(report.observationVerified, isTrue);
      expect(report.declaredSignals.length, 7);
      expect(report.collectedFieldCount, greaterThan(0));
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118PrivacyObservationGate().evaluateWith(
        null,
        _observation(),
      );
      expect(report.state, Sprint118PrivacyState.blocked);
      expect(report.verdict, 'SPRINT_118_PRIVACY_EVIDENCE_UNREADABLE');
      expect(
        report.blockers,
        contains('committed_privacy_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _observation(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118PrivacyState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _observation(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when the observation enables default collection', () {
      final report = _run(_observation(defaultCollection: true));
      expect(report.state, Sprint118PrivacyState.fail);
      expect(report.violations, contains('default_collection_enabled'));
    });

    test('fails when the committed consent gate is not opt-in default off', () {
      final report = _run(
        _observation(),
        anchor: _anchor(consentGate: 'opt-out default ON'),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('consent_gate_not_opt_in_default_off'),
      );
    });

    test('fails when telemetry is claimed executed on the delayed path', () {
      final report = _run(
        _observation(),
        anchor: _anchor(telemetryExecuted: true),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('telemetry_claimed_executed_without_release'),
      );
    });

    test('fails when a signal collects creative content', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'workflow_completion',
            _signal(
              signal: 'workflow_completion',
              collectedFields: const <String>[
                'workflow_outcome',
                'manuscript_body',
              ],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains(
          'creative_content_collected:workflow_completion:manuscript_body',
        ),
      );
    });

    test('fails when a signal collects a secret', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'provider_error',
            _signal(
              signal: 'provider_error',
              collectedFields: const <String>['error_state', 'api_token'],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('secret_collected:provider_error:api_token'),
      );
    });

    test('fails when a signal collects raw payment data', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'billing_state',
            _signal(
              signal: 'billing_state',
              collectedFields: const <String>['event_type', 'card_number'],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('raw_payment_collected:billing_state:card_number'),
      );
    });

    test('fails when a signal does not require consent', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'connection_outcome',
            _signal(
              signal: 'connection_outcome',
              requiresExplicitConsent: false,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('signal_without_consent:connection_outcome'),
      );
    });

    test('fails when a signal is not minimized', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'quota_refresh',
            _signal(signal: 'quota_refresh', minimized: false),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(report.violations, contains('signal_not_minimized:quota_refresh'));
    });

    test('fails when a signal has no disable control', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'sync_outcome',
            _signal(signal: 'sync_outcome', disableControl: false),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('signal_without_disable_control:sync_outcome'),
      );
    });

    test('fails on a non-positive retention', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'usage_metadata',
            _signal(signal: 'usage_metadata', retentionDays: 0),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('retention_nonpositive:usage_metadata:0'),
      );
    });

    test('fails when retention exceeds the maximum', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'usage_metadata',
            _signal(signal: 'usage_metadata', retentionDays: 31),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('retention_exceeds_max:usage_metadata:31:30'),
      );
    });

    test('fails on a duplicate signal', () {
      final signals = <Sprint118ObservationSignal>[
        ...Sprint118PrivacyObservationContract.canonicalObservation.signals,
        _signal(signal: 'connection_outcome'),
      ];
      final report = _run(_observation(signals: signals));
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('duplicate_signal:connection_outcome'),
      );
    });

    test('fails on a signal that collects nothing', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'sync_outcome',
            _signal(signal: 'sync_outcome', collectedFields: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(report.violations, contains('signal_no_fields:sync_outcome'));
    });

    test('fieldCategory classifies creative, secret, and payment fields', () {
      expect(
        Sprint118PrivacyObservationContract.fieldCategory('manuscript_body'),
        'creative',
      );
      expect(
        Sprint118PrivacyObservationContract.fieldCategory('lore_note'),
        'creative',
      );
      expect(
        Sprint118PrivacyObservationContract.fieldCategory('api_token'),
        'secret',
      );
      expect(
        Sprint118PrivacyObservationContract.fieldCategory('card_number'),
        'payment',
      );
      // Aggregate fields stay unclassified.
      expect(
        Sprint118PrivacyObservationContract.fieldCategory('connection_state'),
        isNull,
      );
      expect(
        Sprint118PrivacyObservationContract.fieldCategory('provider_cost'),
        isNull,
      );
      expect(
        Sprint118PrivacyObservationContract.fieldCategory('company_name'),
        isNull,
      );
    });

    test('reports the upstream exclusion vocabulary gap honestly', () {
      // The committed 117.7 witness omits media and raw payment, both named by
      // the 118.5 objective; the gate records the gap as an open item without
      // treating it as a violation, because 118.5 owns the full vocabulary.
      final report = _run(_observation());
      expect(
        report.openItems,
        contains('upstream_exclusion_vocabulary_gap:media'),
      );
      expect(
        report.openItems,
        contains('upstream_exclusion_vocabulary_gap:payment'),
      );
    });

    test('fails when a signal collects media', () {
      final report = _run(
        _observation(
          signals: _replacing(
            'workflow_completion',
            _signal(
              signal: 'workflow_completion',
              collectedFields: const <String>['workflow_outcome', 'screenshot'],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations,
        contains('media_collected:workflow_completion:screenshot'),
      );
    });

    test('fails when a canonical signal is missing', () {
      final signals = <Sprint118ObservationSignal>[
        for (final s
            in Sprint118PrivacyObservationContract.canonicalObservation.signals)
          if (s.signal != 'billing_state') s,
      ];
      final report = _run(_observation(signals: signals));
      expect(report.state, Sprint118PrivacyState.fail);
      expect(report.violations, contains('signal_missing:billing_state'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _observation(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.3/sprint_118_post_release_health_baseline.json',
          ],
        ),
      );
      expect(report.state, Sprint118PrivacyState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });
  });
}
