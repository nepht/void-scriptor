import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_security_health_review.dart';

/// A single security entry. Each test flips exactly the one thing it is about,
/// so a test that flips nothing proves the pass path exists and every other
/// test proves one way the gate refuses to take it.
Sprint118SecurityHealthEntry _entry({
  String signal = 'oauth_alert',
  String referenceState = 'oauth_tests',
  String source =
      'docs/planning/v1.2/sprint_116_security_certification_gate.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118SecurityHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118SecurityHealthReview _review({
  String releaseState = Sprint118SecurityHealthContract.delayedReleaseState,
  List<Sprint118SecurityHealthEntry>? entries,
}) {
  return Sprint118SecurityHealthReview(
    releaseState: releaseState,
    entries: entries ?? Sprint118SecurityHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118SecurityHealthEntry> _replacing(
  String signal,
  Sprint118SecurityHealthEntry replacement,
) {
  return <Sprint118SecurityHealthEntry>[
    for (final e in Sprint118SecurityHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118SecurityHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118SecurityHealthContract.requiredBaselineVerdict,
  String releaseState = Sprint118SecurityHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118SecurityHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118SecurityHealthContract.charterWindowMinutes,
  List<String>? witnessSecurityCertification,
  List<String>? witnessTokenVault,
  List<String>? witnessSessionDevice,
  List<String>? witnessOAuthIdentity,
  List<String>? witnessCredentialSafety,
  List<String>? readableSources,
}) {
  return Sprint118SecurityHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessSecurityCertification:
        witnessSecurityCertification ??
        const <String>[
          'oauth_tests',
          'vault_tests',
          'redirect_tests',
          'session_tests',
          'permission_tests',
          'webhook_tests',
          'dependency_scan',
          'audit_tests',
        ],
    witnessTokenVault:
        witnessTokenVault ??
        const <String>[
          'os_secure_store',
          'no_plaintext',
          'masked_display',
          'reauth',
          'audit_redaction',
          'clipboard_timeout',
        ],
    witnessSessionDevice:
        witnessSessionDevice ??
        const <String>[
          'list_sessions',
          'device_details',
          'trust_state',
          'revoke',
          'force_logout',
          'security_alert',
        ],
    witnessOAuthIdentity:
        witnessOAuthIdentity ??
        const <String>[
          'pkce',
          'state_validation',
          'nonce_when_required',
          'scoped_consent',
          'token_rotation',
          'revocation',
        ],
    witnessCredentialSafety:
        witnessCredentialSafety ??
        const <String>[
          'test_only_credentials',
          'least_privilege',
          'rotation',
          'redaction',
          'no_artifact_leak',
          'revocation',
        ],
    readableSources:
        readableSources ?? Sprint118SecurityHealthContract.canonicalSources,
  );
}

Sprint118SecurityHealthReport _run(
  Sprint118SecurityHealthReview review, {
  Sprint118SecurityHealthAnchor? anchor,
}) {
  return const Sprint118SecurityHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.18 Security Health Review', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118SecurityHealthContract.canonicalStep, '118.18');
      expect(Sprint118SecurityHealthContract.title, 'Security Health Review');
      expect(
        Sprint118SecurityHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_security_health_review.json',
      );
      expect(Sprint118SecurityHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118SecurityHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118SecurityHealthContract.requiredFields.length, 5);
      expect(Sprint118SecurityHealthContract.securitySignals.length, 8);
      expect(Sprint118SecurityHealthContract.canonicalSources.length, 8);
      // Every canonical signal maps to a committed evidence source.
      for (final s in Sprint118SecurityHealthContract.securitySignals) {
        expect(Sprint118SecurityHealthContract.sourceFor(s), isNotEmpty);
      }
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118SecurityHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['oauth_tests', 'permission_tests'],
          <String>['os_secure_store'],
          <String>['security_alert'],
          <String>['pkce'],
          <String>['redaction'],
        ],
      );
      expect(vocab, <String>[
        'oauth_tests',
        'permission_tests',
        'os_secure_store',
        'security_alert',
        'pkce',
        'redaction',
      ]);
    });

    test('canonical review covers the eight signals and claims no live '
        'observation', () {
      final review = Sprint118SecurityHealthContract.canonicalReview;
      expect(review.signals.length, 8);
      expect(review.signals.toSet(), <String>{
        'oauth_alert',
        'vault_health',
        'session_alert',
        'permission_denial',
        'redirect_alert',
        'webhook_alert',
        'dependency_alert',
        'redaction_failure',
      });
      for (final entry in review.entries) {
        expect(entry.observed, isFalse);
        expect(entry.window, greaterThan(0));
        expect(entry.limitations, isNotEmpty);
      }
      expect(review.observedCount, 0);
    });

    test('passes on the canonical review', () {
      final report = _run(_review());
      expect(report.state, Sprint118SecurityHealthState.pass);
      expect(report.verdict, 'SECURITY_HEALTH_REVIEW_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 8);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      // Every canonical signal has a witness state, so no upstream gap is
      // recorded.
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118SecurityHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118SecurityHealthState.blocked);
      expect(report.verdict, 'SPRINT_118_SECURITY_HEALTH_EVIDENCE_UNREADABLE');
      expect(
        report.blockers,
        contains('committed_security_health_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter is not complete', () {
      final report = _run(
        _review(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE'),
      );
      expect(report.state, Sprint118SecurityHealthState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_INCOMPLETE'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _review(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'vault_health',
            _entry(
              signal: 'vault_health',
              referenceState: 'os_secure_store',
              source:
                  'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(
        report.violations,
        contains('security_claims_observation_without_release:vault_health'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'redaction_failure',
            _entry(
              signal: 'redaction_failure',
              referenceState: 'SOMETHING_ELSE',
              source:
                  'docs/planning/v1.2/sprint_116_credential_secret_test_safety.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unknown_reference_state:redaction_failure:SOMETHING_ELSE',
        ),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'session_alert',
            _entry(
              signal: 'session_alert',
              referenceState: 'security_alert',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:session_alert:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'oauth_alert',
            _entry(signal: 'oauth_alert', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:oauth_alert'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'webhook_alert',
            _entry(
              signal: 'webhook_alert',
              referenceState: 'webhook_tests',
              source:
                  'docs/planning/v1.2/sprint_116_security_certification_gate.json',
              limitations: const <String>[],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(report.violations, contains('entry_no_limitations:webhook_alert'));
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'permission_denial',
            _entry(
              signal: 'permission_denial',
              referenceState: 'permission_tests',
              source:
                  'docs/planning/v1.2/sprint_116_security_certification_gate.json',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:permission_denial:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'dependency_alert',
            _entry(
              signal: 'dependency_alert',
              referenceState: 'dependency_scan',
              source:
                  'docs/planning/v1.2/sprint_116_security_certification_gate.json',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:dependency_alert:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118SecurityHealthEntry>[
        ...Sprint118SecurityHealthContract.canonicalReview.entries,
        _entry(signal: 'oauth_alert'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(report.violations, contains('signal_duplicate:oauth_alert'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118SecurityHealthEntry>[
        for (final e in Sprint118SecurityHealthContract.canonicalReview.entries)
          if (e.signal != 'redaction_failure') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(report.violations, contains('signal_missing:redaction_failure'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'oauth_alert',
            _entry(signal: 'unknown_signal', referenceState: 'oauth_tests'),
          ),
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      // The replacement also removes the real 'oauth_alert' entry, so both the
      // unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:oauth_alert'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_116_security_certification_gate.json',
          ],
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessSecurityCertification: const <String>[],
          witnessTokenVault: const <String>[],
          witnessSessionDevice: const <String>[],
          witnessOAuthIdentity: const <String>[],
          witnessCredentialSafety: const <String>[],
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.blocked);
      expect(report.blockers, contains('upstream_security_vocabulary_missing'));
    });

    test('records an open item when a signal carries no_reference_state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'redaction_failure',
            _entry(
              signal: 'redaction_failure',
              referenceState: Sprint118SecurityHealthContract.noReferenceState,
              source:
                  'docs/planning/v1.2/sprint_116_credential_secret_test_safety.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SecurityHealthState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:redaction_failure'),
      );
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118SecurityHealthContract.sourceFor('oauth_alert'),
        'docs/planning/v1.2/sprint_116_security_certification_gate.json',
      );
      expect(
        Sprint118SecurityHealthContract.sourceFor('redaction_failure'),
        'docs/planning/v1.2/sprint_116_credential_secret_test_safety.json',
      );
      expect(Sprint118SecurityHealthContract.sourceFor('unknown'), '');
    });
  });
}
