import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_accessibility_health.dart';

/// A single accessibility health entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118AccessibilityHealthEntry _entry({
  String signal = 'keyboard_blocker',
  String referenceState = 'keyboard_complete',
  String source =
      'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118AccessibilityHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118AccessibilityHealthReview _review({
  String releaseState =
      Sprint118AccessibilityHealthContract.delayedReleaseState,
  List<Sprint118AccessibilityHealthEntry>? entries,
}) {
  return Sprint118AccessibilityHealthReview(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118AccessibilityHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118AccessibilityHealthEntry> _replacing(
  String signal,
  Sprint118AccessibilityHealthEntry replacement,
) {
  return <Sprint118AccessibilityHealthEntry>[
    for (final e
        in Sprint118AccessibilityHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118AccessibilityHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118AccessibilityHealthContract.requiredBaselineVerdict,
  String releaseState =
      Sprint118AccessibilityHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118AccessibilityHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118AccessibilityHealthContract.charterWindowMinutes,
  List<String>? witnessInteractionBaseline,
  List<String>? witnessKeyboardScreenReader,
  List<String>? witnessAccessibilityHealth,
  List<String>? witnessBrandVisual,
  List<String>? witnessStorageUsageCards,
  List<String>? readableSources,
}) {
  return Sprint118AccessibilityHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessInteractionBaseline:
        witnessInteractionBaseline ??
        const <String>[
          'keyboard_complete',
          'visible_focus',
          'screen_reader_labels',
          'chart_text_alternative',
          '44px_touch_target',
          '200_percent_scale',
        ],
    witnessKeyboardScreenReader:
        witnessKeyboardScreenReader ??
        const <String>[
          'focus_order',
          'keyboard_results',
          'screen_reader_results',
          'status_announcements',
          'dialog_results',
          'chart_alternatives',
        ],
    witnessAccessibilityHealth:
        witnessAccessibilityHealth ??
        const <String>[
          'keyboard_blocker',
          'screen_reader_blocker',
          'focus_loss',
          'scaling_break',
          'contrast_issue',
          'motion_issue',
          'nonvisual_gap',
        ],
    witnessBrandVisual:
        witnessBrandVisual ??
        const <String>[
          'icon_review',
          'visual_regression',
          'breakpoints',
          'fallbacks',
          'keyboard',
          'screen_reader',
          'chart_alternatives',
        ],
    witnessStorageUsageCards:
        witnessStorageUsageCards ??
        const <String>[
          'icon',
          'accessible_progress',
          'quota_unknown_state',
          'freshness',
          'error_state',
          'manage_action',
        ],
    readableSources:
        readableSources ??
        Sprint118AccessibilityHealthContract.canonicalSources,
  );
}

Sprint118AccessibilityHealthReport _run(
  Sprint118AccessibilityHealthReview review, {
  Sprint118AccessibilityHealthAnchor? anchor,
}) {
  return const Sprint118AccessibilityHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.15 Accessibility Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118AccessibilityHealthContract.canonicalStep, '118.15');
      expect(
        Sprint118AccessibilityHealthContract.title,
        'Accessibility Health',
      );
      expect(
        Sprint118AccessibilityHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_accessibility_health.json',
      );
      expect(Sprint118AccessibilityHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118AccessibilityHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118AccessibilityHealthContract.requiredFields.length, 5);
      expect(
        Sprint118AccessibilityHealthContract.accessibilitySignals.length,
        8,
      );
      expect(Sprint118AccessibilityHealthContract.canonicalSources.length, 8);
      // Every canonical signal maps to a committed evidence source.
      for (final s
          in Sprint118AccessibilityHealthContract.accessibilitySignals) {
        expect(Sprint118AccessibilityHealthContract.sourceFor(s), isNotEmpty);
      }
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118AccessibilityHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['keyboard_complete', 'visible_focus'],
          <String>['status_announcements', 'chart_alternatives'],
          <String>['contrast_issue', 'motion_issue'],
          <String>['keyboard', 'screen_reader'],
          <String>['accessible_progress', 'manage_action'],
        ],
      );
      expect(vocab, <String>[
        'keyboard_complete',
        'visible_focus',
        'status_announcements',
        'chart_alternatives',
        'contrast_issue',
        'motion_issue',
        'keyboard',
        'screen_reader',
        'accessible_progress',
        'manage_action',
      ]);
    });

    test('canonical review covers the eight signals and claims no live '
        'observation', () {
      final review = Sprint118AccessibilityHealthContract.canonicalReview;
      expect(review.signals.length, 8);
      expect(review.signals.toSet(), <String>{
        'keyboard_blocker',
        'focus_issue',
        'screen_reader_issue',
        'status_issue',
        'progress_issue',
        'chart_gap',
        'target_issue',
        'contrast_issue',
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
      expect(report.state, Sprint118AccessibilityHealthState.pass);
      expect(report.verdict, 'ACCESSIBILITY_HEALTH_VERIFIED_LOCAL');
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
      final report = const Sprint118AccessibilityHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118AccessibilityHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_ACCESSIBILITY_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_accessibility_health_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.blocked);
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
      expect(report.state, Sprint118AccessibilityHealthState.blocked);
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
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'keyboard_blocker',
            _entry(
              signal: 'keyboard_blocker',
              referenceState: 'keyboard_complete',
              source:
                  'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(
        report.violations,
        contains(
          'accessibility_claims_observation_without_release:keyboard_blocker',
        ),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'contrast_issue',
            _entry(
              signal: 'contrast_issue',
              referenceState: 'SOMETHING_ELSE',
              source: 'docs/planning/v1.2/sprint_114_accessibility_health.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(
        report.violations,
        contains('entry_unknown_reference_state:contrast_issue:SOMETHING_ELSE'),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'chart_gap',
            _entry(
              signal: 'chart_gap',
              referenceState: 'chart_text_alternative',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:chart_gap:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'keyboard_blocker',
            _entry(signal: 'keyboard_blocker', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:keyboard_blocker'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'focus_issue',
            _entry(
              signal: 'focus_issue',
              referenceState: 'visible_focus',
              source:
                  'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
              limitations: const <String>[],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(report.violations, contains('entry_no_limitations:focus_issue'));
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'screen_reader_issue',
            _entry(
              signal: 'screen_reader_issue',
              referenceState: 'screen_reader_labels',
              source:
                  'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:screen_reader_issue:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'progress_issue',
            _entry(
              signal: 'progress_issue',
              referenceState: 'accessible_progress',
              source: 'docs/planning/v1.2/sprint_115_storage_usage_cards.json',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:progress_issue:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118AccessibilityHealthEntry>[
        ...Sprint118AccessibilityHealthContract.canonicalReview.entries,
        _entry(signal: 'keyboard_blocker'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(report.violations, contains('signal_duplicate:keyboard_blocker'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118AccessibilityHealthEntry>[
        for (final e
            in Sprint118AccessibilityHealthContract.canonicalReview.entries)
          if (e.signal != 'contrast_issue') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(report.violations, contains('signal_missing:contrast_issue'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'keyboard_blocker',
            _entry(signal: 'unknown_signal', referenceState: 'visible_focus'),
          ),
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      // The replacement also removes the real 'keyboard_blocker' entry, so both
      // the unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:keyboard_blocker'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
          ],
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessInteractionBaseline: const <String>[],
          witnessKeyboardScreenReader: const <String>[],
          witnessAccessibilityHealth: const <String>[],
          witnessBrandVisual: const <String>[],
          witnessStorageUsageCards: const <String>[],
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.blocked);
      expect(
        report.blockers,
        contains('upstream_accessibility_vocabulary_missing'),
      );
    });

    test('records an open item when a signal carries no_reference_state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'contrast_issue',
            _entry(
              signal: 'contrast_issue',
              referenceState:
                  Sprint118AccessibilityHealthContract.noReferenceState,
              source: 'docs/planning/v1.2/sprint_114_accessibility_health.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118AccessibilityHealthState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:contrast_issue'),
      );
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118AccessibilityHealthContract.sourceFor('keyboard_blocker'),
        'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
      );
      expect(
        Sprint118AccessibilityHealthContract.sourceFor('contrast_issue'),
        'docs/planning/v1.2/sprint_114_accessibility_health.json',
      );
      expect(Sprint118AccessibilityHealthContract.sourceFor('unknown'), '');
    });
  });
}
