import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_oauth_reauth_health.dart';

/// A single OAuth/reauthentication health entry. Each test flips exactly the
/// one thing it is about, so a test that flips nothing proves the pass path
/// exists and every other test proves one way the gate refuses to take it.
Sprint118OAuthReauthHealthEntry _entry({
  String signal = 'callback_error',
  String referenceState = 'callback',
  String source =
      'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json',
  int window = 60,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118OAuthReauthHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118OAuthReauthHealthReview _review({
  String releaseState = Sprint118OAuthReauthHealthContract.delayedReleaseState,
  List<Sprint118OAuthReauthHealthEntry>? entries,
}) {
  return Sprint118OAuthReauthHealthReview(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118OAuthReauthHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118OAuthReauthHealthEntry> _replacing(
  String signal,
  Sprint118OAuthReauthHealthEntry replacement,
) {
  return <Sprint118OAuthReauthHealthEntry>[
    for (final e in Sprint118OAuthReauthHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118OAuthReauthHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118OAuthReauthHealthContract.requiredBaselineVerdict,
  String releaseState = Sprint118OAuthReauthHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118OAuthReauthHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118OAuthReauthHealthContract.charterWindowMinutes,
  List<String>? witnessOAuthSurfaces,
  List<String>? witnessReauthAcceptance,
  List<String>? readableSources,
}) {
  return Sprint118OAuthReauthHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessOAuthSurfaces:
        witnessOAuthSurfaces ??
        const <String>[
          'flow_type',
          'pkce_method',
          'state',
          'nonce',
          'scoped_consent',
          'callback',
          'token_rotation',
          'unlink',
          'secret_surface',
        ],
    witnessReauthAcceptance:
        witnessReauthAcceptance ??
        const <String>[
          'expiry_notice',
          'affected_scope',
          'reauth',
          'retry',
          'revoke',
          'local_data_preserved',
        ],
    readableSources:
        readableSources ?? Sprint118OAuthReauthHealthContract.canonicalSources,
  );
}

Sprint118OAuthReauthHealthReport _run(
  Sprint118OAuthReauthHealthReview review, {
  Sprint118OAuthReauthHealthAnchor? anchor,
}) {
  return const Sprint118OAuthReauthHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.8 OAuth & Reauthentication Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118OAuthReauthHealthContract.canonicalStep, '118.8');
      expect(
        Sprint118OAuthReauthHealthContract.title,
        'OAuth & Reauthentication Health',
      );
      expect(
        Sprint118OAuthReauthHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_oauth_reauth_health.json',
      );
      expect(Sprint118OAuthReauthHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118OAuthReauthHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118OAuthReauthHealthContract.requiredFields.length, 5);
      expect(Sprint118OAuthReauthHealthContract.oauthHealthSignals.length, 6);
      expect(Sprint118OAuthReauthHealthContract.canonicalSources.length, 6);
      // Every canonical signal maps to a distinct committed evidence source.
      final sources = <String>{
        for (final s in Sprint118OAuthReauthHealthContract.oauthHealthSignals)
          Sprint118OAuthReauthHealthContract.sourceFor(s),
      };
      expect(sources.length, 6);
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order (OAuth surfaces, then reauth acceptance).
      final vocab = Sprint118OAuthReauthHealthContract.stateVocabulary(
        const <String>['callback', 'state', 'unlink'],
        const <String>['reauth', 'state'],
      );
      expect(vocab, <String>['callback', 'state', 'unlink', 'reauth']);
    });

    test('canonical review covers the six signals and claims no live '
        'observation', () {
      final review = Sprint118OAuthReauthHealthContract.canonicalReview;
      expect(review.signals.length, 6);
      expect(review.signals.toSet(), <String>{
        'callback_error',
        'state_failure',
        'rotation_failure',
        'reauth_completion',
        'scope_change',
        'provider_revoke',
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
      expect(report.state, Sprint118OAuthReauthHealthState.pass);
      expect(report.verdict, 'OAUTH_REAUTH_HEALTH_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 6);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118OAuthReauthHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_OAUTH_REAUTH_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_oauth_reauth_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.blocked);
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
      expect(report.state, Sprint118OAuthReauthHealthState.blocked);
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
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'reauth_completion',
            _entry(
              signal: 'reauth_completion',
              referenceState: 'reauth',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations,
        contains('oauth_claims_observation_without_release:reauth_completion'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'provider_revoke',
            _entry(signal: 'provider_revoke', referenceState: 'SOMETHING_ELSE'),
          ),
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unknown_reference_state:provider_revoke:SOMETHING_ELSE',
        ),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'state_failure',
            _entry(
              signal: 'state_failure',
              referenceState: 'state',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:state_failure:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'callback_error',
            _entry(signal: 'callback_error', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:callback_error'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'rotation_failure',
            _entry(signal: 'rotation_failure', limitations: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations,
        contains('entry_no_limitations:rotation_failure'),
      );
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'callback_error',
            _entry(signal: 'callback_error', window: 0),
          ),
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:callback_error:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'scope_change',
            _entry(
              signal: 'scope_change',
              referenceState: 'scoped_consent',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:scope_change:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118OAuthReauthHealthEntry>[
        ...Sprint118OAuthReauthHealthContract.canonicalReview.entries,
        _entry(signal: 'callback_error'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(report.violations, contains('signal_duplicate:callback_error'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118OAuthReauthHealthEntry>[
        for (final e
            in Sprint118OAuthReauthHealthContract.canonicalReview.entries)
          if (e.signal != 'scope_change') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(report.violations, contains('signal_missing:scope_change'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'callback_error',
            _entry(signal: 'unknown_signal', referenceState: 'callback'),
          ),
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      // The replacement also removes the real 'callback_error' entry, so both
      // the unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:callback_error'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json',
          ],
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessOAuthSurfaces: const <String>[],
          witnessReauthAcceptance: const <String>[],
        ),
      );
      expect(report.state, Sprint118OAuthReauthHealthState.blocked);
      expect(report.blockers, contains('upstream_oauth_vocabulary_missing'));
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118OAuthReauthHealthContract.sourceFor('callback_error'),
        'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json',
      );
      expect(
        Sprint118OAuthReauthHealthContract.sourceFor('provider_revoke'),
        'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
      );
      expect(Sprint118OAuthReauthHealthContract.sourceFor('unknown'), '');
    });
  });
}
