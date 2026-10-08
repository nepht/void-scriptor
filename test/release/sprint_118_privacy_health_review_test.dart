import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_privacy_health_review.dart';

Sprint118PrivacyHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118PrivacyHealthContract.requiredBaselineVerdict,
  String releaseState = Sprint118PrivacyHealthContract.delayedReleaseState,
  String observationState = 'pass',
  String observationVerdict =
      Sprint118PrivacyHealthContract.requiredObservationVerdict,
  String observationReleaseState =
      Sprint118PrivacyHealthContract.delayedReleaseState,
  String complianceStatus = 'VERIFIED-LOCAL',
  bool collectionOff = true,
  String consentGate = Sprint118PrivacyHealthContract.requiredConsentGate,
  bool telemetryExecuted = false,
  int charterWindowMinutes = 60480,
  List<String>? readableSources,
}) {
  return Sprint118PrivacyHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: 'pass',
    charterVerdict: Sprint118PrivacyHealthContract.requiredCharterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    observationState: observationState,
    observationVerdict: observationVerdict,
    observationReleaseState: observationReleaseState,
    observationAcceptance: const <String>[
      'creative_content_excluded',
      'secrets_excluded',
      'raw_payment_excluded',
      'consent',
      'minimization',
      'retention',
      'disable_control',
    ],
    complianceStatus: complianceStatus,
    dataFlowOutputs: const <String>[
      'data_flow',
      'classification',
      'consent',
      'retention',
      'deletion',
      'external_transfer',
      'redaction',
      'privacy_defaults',
    ],
    monitoringSignals: const <String>[
      'connection_outcome',
      'quota_refresh',
      'sync_outcome',
      'provider_error',
      'usage_metadata',
      'billing_state',
      'workflow_completion',
    ],
    collectionOff: collectionOff,
    consentGate: consentGate,
    telemetryExecuted: telemetryExecuted,
    readableSources:
        readableSources ??
        <String>[
          Sprint118PrivacyHealthContract.baselineManifestPath,
          Sprint118PrivacyHealthContract.charterManifestPath,
          Sprint118PrivacyHealthContract.observationManifestPath,
          Sprint118PrivacyHealthContract.complianceManifestPath,
          Sprint118PrivacyHealthContract.dataFlowManifestPath,
          Sprint118PrivacyHealthContract.monitoringManifestPath,
        ],
  );
}

Sprint118PrivacyHealthReview _review({
  List<Sprint118PrivacyHealthEntry>? entries,
  String releaseState = Sprint118PrivacyHealthContract.delayedReleaseState,
}) {
  return Sprint118PrivacyHealthReview(
    releaseState: releaseState,
    entries: entries ?? Sprint118PrivacyHealthContract.canonicalReview.entries,
  );
}

List<Sprint118PrivacyHealthEntry> _withReplacement(
  String signal,
  Sprint118PrivacyHealthEntry replacement,
) {
  return <Sprint118PrivacyHealthEntry>[
    for (final entry in Sprint118PrivacyHealthContract.canonicalReview.entries)
      if (entry.signal == signal) replacement else entry,
  ];
}

void main() {
  group('118.19 Privacy Health Review', () {
    test('pins the canonical contract', () {
      expect(Sprint118PrivacyHealthContract.canonicalStep, '118.19');
      expect(Sprint118PrivacyHealthContract.title, 'Privacy Health Review');
      expect(Sprint118PrivacyHealthContract.requiredFields.length, 9);
      expect(Sprint118PrivacyHealthContract.privacySignals.length, 8);
      for (final signal in Sprint118PrivacyHealthContract.privacySignals) {
        expect(Sprint118PrivacyHealthContract.sourceFor(signal), isNotEmpty);
      }
    });

    test('canonical review covers all signals without live observation', () {
      final review = Sprint118PrivacyHealthContract.canonicalReview;
      expect(review.signals.toSet(), <String>{
        'consent_issue',
        'destination_issue',
        'retention_issue',
        'deletion_issue',
        'disconnect_issue',
        'telemetry_issue',
        'metadata_issue',
        'transfer_issue',
      });
      expect(review.observedCount, 0);
      for (final entry in review.entries) {
        expect(entry.destination, isNotEmpty);
        expect(entry.limitations, isNotEmpty);
        expect(entry.retentionDays, lessThanOrEqualTo(30));
      }
    });

    test('passes the canonical review and loader', () {
      final report = const Sprint118PrivacyHealthGate().evaluateWith(
        _anchor(),
        _review(),
      );
      expect(report.state, Sprint118PrivacyHealthState.pass);
      expect(report.verdict, 'PRIVACY_HEALTH_REVIEW_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.observedCount, 0);
      expect(const Sprint118PrivacyHealthLoader().loadAnchor(), isNotNull);
    });

    test('rejects a live observation claim', () {
      final entry = Sprint118PrivacyHealthContract.canonicalReview.entries[0];
      final report = const Sprint118PrivacyHealthGate().evaluateWith(
        _anchor(),
        _review(
          entries: _withReplacement(
            entry.signal,
            Sprint118PrivacyHealthEntry(
              signal: entry.signal,
              referenceState: entry.referenceState,
              source: entry.source,
              destination: entry.destination,
              retentionDays: entry.retentionDays,
              limitations: entry.limitations,
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyHealthState.fail);
      expect(
        report.violations,
        contains('live_observation_claimed:consent_issue'),
      );
    });

    test('rejects an unknown, missing, or duplicate signal', () {
      final entries =
          [...Sprint118PrivacyHealthContract.canonicalReview.entries]
            ..removeAt(0)
            ..add(
              const Sprint118PrivacyHealthEntry(
                signal: 'unknown',
                referenceState: 'consent',
                source: Sprint118PrivacyHealthContract.observationManifestPath,
                destination: 'local',
                retentionDays: 30,
                limitations: <String>['fixture'],
              ),
            );
      final report = const Sprint118PrivacyHealthGate().evaluateWith(
        _anchor(),
        _review(entries: entries),
      );
      expect(report.state, Sprint118PrivacyHealthState.fail);
      expect(report.violations, contains('signal_unknown:unknown'));
      expect(report.violations, contains('signal_missing:consent_issue'));
    });

    test('rejects missing privacy controls', () {
      final entry = Sprint118PrivacyHealthContract.canonicalReview.entries[0];
      final report = const Sprint118PrivacyHealthGate().evaluateWith(
        _anchor(),
        _review(
          entries: _withReplacement(
            entry.signal,
            Sprint118PrivacyHealthEntry(
              signal: entry.signal,
              referenceState: entry.referenceState,
              source: entry.source,
              destination: '',
              retentionDays: 31,
              limitations: const <String>[],
              consentExplicit: false,
              deletionSupported: false,
              disconnectSupported: false,
              telemetryDisabled: false,
              metadataMinimized: false,
              transferExplicit: false,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyHealthState.fail);
      expect(report.violations, contains('destination_missing:consent_issue'));
      expect(
        report.violations,
        contains('retention_out_of_bounds:consent_issue'),
      );
      expect(report.violations, contains('consent_missing:consent_issue'));
    });

    test('rejects unknown reference state and unreadable source', () {
      final entry = Sprint118PrivacyHealthContract.canonicalReview.entries[0];
      final report = const Sprint118PrivacyHealthGate().evaluateWith(
        _anchor(readableSources: const <String>[]),
        _review(
          entries: _withReplacement(
            entry.signal,
            const Sprint118PrivacyHealthEntry(
              signal: 'consent_issue',
              referenceState: 'not_a_privacy_state',
              source: 'missing.json',
              destination: 'local',
              retentionDays: 30,
              limitations: <String>['fixture'],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118PrivacyHealthState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:consent_issue'),
      );
      expect(report.violations, contains('source_unreadable:consent_issue'));
    });

    test(
      'blocks when upstream baseline or privacy observation is not verified',
      () {
        final report = const Sprint118PrivacyHealthGate().evaluateWith(
          _anchor(baselineState: 'blocked', observationState: 'blocked'),
          _review(),
        );
        expect(report.state, Sprint118PrivacyHealthState.blocked);
        expect(report.blockers, contains('baseline_not_frozen'));
        expect(report.blockers, contains('privacy_observation_not_verified'));
      },
    );

    test(
      'blocks telemetry that claims to have executed on delayed release',
      () {
        final report = const Sprint118PrivacyHealthGate().evaluateWith(
          _anchor(telemetryExecuted: true),
          _review(),
        );
        expect(report.state, Sprint118PrivacyHealthState.fail);
        expect(
          report.violations,
          contains('telemetry_claimed_executed_on_delayed_path'),
        );
      },
    );

    test('rejects a release-state mismatch and invalid consent default', () {
      final report = const Sprint118PrivacyHealthGate().evaluateWith(
        _anchor(releaseState: 'GA_RELEASED', collectionOff: false),
        _review(releaseState: 'GA_RELEASED'),
      );
      expect(report.state, Sprint118PrivacyHealthState.fail);
      expect(report.violations, contains('consent_default_not_opt_in_off'));
      expect(report.violations, isNotEmpty);
    });
  });
}
