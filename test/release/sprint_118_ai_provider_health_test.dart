import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_ai_provider_health.dart';

/// A single AI provider health entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118AiProviderHealthEntry _entry({
  String signal = 'model_discovery',
  String referenceState = 'model_discovery',
  String source = 'docs/planning/v1.2/sprint_116_local_ai_certification.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118AiProviderHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118AiProviderHealthReview _review({
  String releaseState = Sprint118AiProviderHealthContract.delayedReleaseState,
  List<Sprint118AiProviderHealthEntry>? entries,
}) {
  return Sprint118AiProviderHealthReview(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118AiProviderHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118AiProviderHealthEntry> _replacing(
  String signal,
  Sprint118AiProviderHealthEntry replacement,
) {
  return <Sprint118AiProviderHealthEntry>[
    for (final e in Sprint118AiProviderHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118AiProviderHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118AiProviderHealthContract.requiredBaselineVerdict,
  String releaseState = Sprint118AiProviderHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118AiProviderHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118AiProviderHealthContract.charterWindowMinutes,
  List<String>? witnessLocalAiFields,
  List<String>? witnessOpenaiFields,
  List<String>? witnessOpenrouterFields,
  List<String>? witnessExternalDependencySignals,
  List<String>? witnessModelSettingsAcceptance,
  List<String>? readableSources,
}) {
  return Sprint118AiProviderHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessLocalAiFields:
        witnessLocalAiFields ??
        const <String>[
          'provider_id',
          'model_discovery',
          'hardware_limits',
          'storage',
          'lifecycle',
          'privacy',
          'offline_use',
          'failure_isolation',
        ],
    witnessOpenaiFields:
        witnessOpenaiFields ??
        const <String>[
          'provider_id',
          'supported_modalities',
          'models',
          'auth',
          'cancellation',
          'usage_metadata',
          'cost_labels',
          'privacy',
          'errors',
          'limitations',
        ],
    witnessOpenrouterFields:
        witnessOpenrouterFields ??
        const <String>[
          'provider_id',
          'routing_metadata',
          'models',
          'provider_fallback',
          'usage',
          'cost',
          'privacy_destination',
          'errors',
          'limitations',
        ],
    witnessExternalDependencySignals:
        witnessExternalDependencySignals ??
        const <String>[
          'provider_availability',
          'timeout',
          'throttling',
          'auth_expiry',
          'cost_visibility',
          'fallback_success',
          'consent_failure',
        ],
    witnessModelSettingsAcceptance:
        witnessModelSettingsAcceptance ??
        const <String>[
          'connect',
          'model_select',
          'fallback',
          'timeout',
          'budget',
          'prefer_local',
          'health_test',
        ],
    readableSources:
        readableSources ?? Sprint118AiProviderHealthContract.canonicalSources,
  );
}

Sprint118AiProviderHealthReport _run(
  Sprint118AiProviderHealthReview review, {
  Sprint118AiProviderHealthAnchor? anchor,
}) {
  return const Sprint118AiProviderHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.11 AI Provider Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118AiProviderHealthContract.canonicalStep, '118.11');
      expect(Sprint118AiProviderHealthContract.title, 'AI Provider Health');
      expect(
        Sprint118AiProviderHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_ai_provider_health.json',
      );
      expect(Sprint118AiProviderHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118AiProviderHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118AiProviderHealthContract.requiredFields.length, 5);
      expect(Sprint118AiProviderHealthContract.aiProviderSignals.length, 8);
      expect(Sprint118AiProviderHealthContract.canonicalSources.length, 8);
      // Every canonical signal maps to a committed evidence source.
      final sources = <String>{
        for (final s in Sprint118AiProviderHealthContract.aiProviderSignals)
          Sprint118AiProviderHealthContract.sourceFor(s),
      };
      expect(sources.length, 8);
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118AiProviderHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['model_discovery', 'cancellation'],
          <String>['cancellation', 'usage_metadata'],
          <String>['privacy_destination', 'provider_fallback'],
          <String>['throttling', 'provider_availability'],
          <String>['fallback', 'health_test'],
        ],
      );
      expect(vocab, <String>[
        'model_discovery',
        'cancellation',
        'usage_metadata',
        'privacy_destination',
        'provider_fallback',
        'throttling',
        'provider_availability',
        'fallback',
        'health_test',
      ]);
    });

    test('canonical review covers the eight signals and claims no live '
        'observation', () {
      final review = Sprint118AiProviderHealthContract.canonicalReview;
      expect(review.signals.length, 8);
      expect(review.signals.toSet(), <String>{
        'model_discovery',
        'job_success',
        'cancellation',
        'usage_match',
        'cost_label',
        'fallback',
        'throttling',
        'destination',
      });
      for (final entry in review.entries) {
        expect(entry.observed, isFalse);
        expect(entry.window, greaterThan(0));
        expect(entry.limitations, isNotEmpty);
      }
      expect(review.observedCount, 0);
    });

    test('job_success carries the no_reference_state marker', () {
      final review = Sprint118AiProviderHealthContract.canonicalReview;
      final job = review.entries.firstWhere((e) => e.signal == 'job_success');
      expect(
        job.referenceState,
        Sprint118AiProviderHealthContract.noReferenceState,
      );
    });

    test('passes on the canonical review', () {
      final report = _run(_review());
      expect(report.state, Sprint118AiProviderHealthState.pass);
      expect(report.verdict, 'AI_PROVIDER_HEALTH_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 8);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      // The only open item is the honest upstream gap for job_success.
      expect(report.openItems, <String>[
        'upstream_state_vocabulary_gap:job_success',
      ]);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118AiProviderHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118AiProviderHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_AI_PROVIDER_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_ai_provider_health_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.blocked);
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
      expect(report.state, Sprint118AiProviderHealthState.blocked);
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
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'cancellation',
            _entry(
              signal: 'cancellation',
              referenceState: 'cancellation',
              source:
                  'docs/planning/v1.2/sprint_116_openai_connector_certification.json',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(
        report.violations,
        contains('provider_claims_observation_without_release:cancellation'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'throttling',
            _entry(
              signal: 'throttling',
              referenceState: 'SOMETHING_ELSE',
              source:
                  'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(
        report.violations,
        contains('entry_unknown_reference_state:throttling:SOMETHING_ELSE'),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'destination',
            _entry(
              signal: 'destination',
              referenceState: 'privacy_destination',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:destination:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'model_discovery',
            _entry(signal: 'model_discovery', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:model_discovery'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'cost_label',
            _entry(
              signal: 'cost_label',
              referenceState: 'cost_labels',
              source:
                  'docs/planning/v1.2/sprint_116_anthropic_connector_certification.json',
              limitations: const <String>[],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(report.violations, contains('entry_no_limitations:cost_label'));
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'usage_match',
            _entry(
              signal: 'usage_match',
              referenceState: 'usage_metadata',
              source:
                  'docs/planning/v1.2/sprint_116_gemini_connector_certification.json',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:usage_match:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'fallback',
            _entry(
              signal: 'fallback',
              referenceState: 'provider_fallback',
              source:
                  'docs/planning/v1.2/sprint_115_ai_connection_model_settings.json',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:fallback:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118AiProviderHealthEntry>[
        ...Sprint118AiProviderHealthContract.canonicalReview.entries,
        _entry(signal: 'model_discovery'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(report.violations, contains('signal_duplicate:model_discovery'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118AiProviderHealthEntry>[
        for (final e
            in Sprint118AiProviderHealthContract.canonicalReview.entries)
          if (e.signal != 'cancellation') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(report.violations, contains('signal_missing:cancellation'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'model_discovery',
            _entry(signal: 'unknown_signal', referenceState: 'model_discovery'),
          ),
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      // The replacement also removes the real 'model_discovery' entry, so both
      // the unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:model_discovery'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_116_local_ai_certification.json',
          ],
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessLocalAiFields: const <String>[],
          witnessOpenaiFields: const <String>[],
          witnessOpenrouterFields: const <String>[],
          witnessExternalDependencySignals: const <String>[],
          witnessModelSettingsAcceptance: const <String>[],
        ),
      );
      expect(report.state, Sprint118AiProviderHealthState.blocked);
      expect(
        report.blockers,
        contains('upstream_ai_provider_vocabulary_missing'),
      );
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118AiProviderHealthContract.sourceFor('model_discovery'),
        'docs/planning/v1.2/sprint_116_local_ai_certification.json',
      );
      expect(
        Sprint118AiProviderHealthContract.sourceFor('destination'),
        'docs/planning/v1.2/sprint_116_openrouter_connector_certification.json',
      );
      expect(Sprint118AiProviderHealthContract.sourceFor('unknown'), '');
    });
  });
}
