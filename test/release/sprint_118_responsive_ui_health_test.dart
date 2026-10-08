import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_responsive_ui_health.dart';

/// A single responsive UI health entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ResponsiveUiHealthEntry _entry({
  String signal = 'overflow',
  String referenceState = 'no_horizontal_overflow',
  String source =
      'docs/planning/v1.2/sprint_115_desktop_tablet_adaptation.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118ResponsiveUiHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118ResponsiveUiHealthReview _review({
  String releaseState = Sprint118ResponsiveUiHealthContract.delayedReleaseState,
  List<Sprint118ResponsiveUiHealthEntry>? entries,
}) {
  return Sprint118ResponsiveUiHealthReview(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118ResponsiveUiHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118ResponsiveUiHealthEntry> _replacing(
  String signal,
  Sprint118ResponsiveUiHealthEntry replacement,
) {
  return <Sprint118ResponsiveUiHealthEntry>[
    for (final e in Sprint118ResponsiveUiHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118ResponsiveUiHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118ResponsiveUiHealthContract.requiredBaselineVerdict,
  String releaseState = Sprint118ResponsiveUiHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ResponsiveUiHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118ResponsiveUiHealthContract.charterWindowMinutes,
  List<String>? witnessGridSystemViewports,
  List<String>? witnessWideDesktopAcceptance,
  List<String>? witnessDesktopTabletAcceptance,
  List<String>? witnessMobileAcceptance,
  List<String>? witnessBrandVisualAcceptance,
  List<String>? readableSources,
}) {
  return Sprint118ResponsiveUiHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessGridSystemViewports:
        witnessGridSystemViewports ??
        const <String>[
          '1536x1024_reference',
          '1440_plus',
          '1180_to_1439',
          '900_to_1179',
          '600_to_899',
          'under_600',
        ],
    witnessWideDesktopAcceptance:
        witnessWideDesktopAcceptance ??
        const <String>[
          'layout_dimensions',
          'no_overlap',
          'scroll_containment',
          'consistent_cards',
          'right_rail',
          'status_bar',
        ],
    witnessDesktopTabletAcceptance:
        witnessDesktopTabletAcceptance ??
        const <String>[
          'right_drawer',
          'collapsed_nav',
          'two_column',
          'scrollable_tabs',
          'no_horizontal_overflow',
          'state_preserved',
        ],
    witnessMobileAcceptance:
        witnessMobileAcceptance ??
        const <String>[
          'single_column',
          'provider_sheet',
          'safe_actions',
          '44px_targets',
          'text_alternatives',
          'no_clipped_content',
        ],
    witnessBrandVisualAcceptance:
        witnessBrandVisualAcceptance ??
        const <String>[
          'icon_review',
          'visual_regression',
          'breakpoints',
          'fallbacks',
          'keyboard',
          'screen_reader',
          'chart_alternatives',
        ],
    readableSources:
        readableSources ?? Sprint118ResponsiveUiHealthContract.canonicalSources,
  );
}

Sprint118ResponsiveUiHealthReport _run(
  Sprint118ResponsiveUiHealthReview review, {
  Sprint118ResponsiveUiHealthAnchor? anchor,
}) {
  return const Sprint118ResponsiveUiHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.14 Responsive UI Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118ResponsiveUiHealthContract.canonicalStep, '118.14');
      expect(Sprint118ResponsiveUiHealthContract.title, 'Responsive UI Health');
      expect(
        Sprint118ResponsiveUiHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_responsive_ui_health.json',
      );
      expect(Sprint118ResponsiveUiHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118ResponsiveUiHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118ResponsiveUiHealthContract.requiredFields.length, 5);
      expect(Sprint118ResponsiveUiHealthContract.responsiveSignals.length, 7);
      expect(Sprint118ResponsiveUiHealthContract.canonicalSources.length, 7);
      // Every canonical signal maps to a committed evidence source.
      for (final s in Sprint118ResponsiveUiHealthContract.responsiveSignals) {
        expect(Sprint118ResponsiveUiHealthContract.sourceFor(s), isNotEmpty);
      }
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118ResponsiveUiHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['1440_plus', 'under_600'],
          <String>['no_overlap', 'status_bar'],
          <String>['right_drawer', 'no_horizontal_overflow'],
          <String>['no_clipped_content', 'single_column'],
          <String>['breakpoints', 'chart_alternatives'],
        ],
      );
      expect(vocab, <String>[
        '1440_plus',
        'under_600',
        'no_overlap',
        'status_bar',
        'right_drawer',
        'no_horizontal_overflow',
        'no_clipped_content',
        'single_column',
        'breakpoints',
        'chart_alternatives',
      ]);
    });

    test('canonical review covers the seven signals and claims no live '
        'observation', () {
      final review = Sprint118ResponsiveUiHealthContract.canonicalReview;
      expect(review.signals.length, 7);
      expect(review.signals.toSet(), <String>{
        'overflow',
        'layout_shift',
        'clipping',
        'drawer_failure',
        'tab_failure',
        'chart_issue',
        'scaling_issue',
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
      expect(report.state, Sprint118ResponsiveUiHealthState.pass);
      expect(report.verdict, 'RESPONSIVE_UI_HEALTH_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 7);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      // Every canonical signal has a witness state, so no upstream gap is
      // recorded.
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ResponsiveUiHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_RESPONSIVE_UI_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_responsive_ui_health_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.blocked);
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
      expect(report.state, Sprint118ResponsiveUiHealthState.blocked);
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
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'overflow',
            _entry(
              signal: 'overflow',
              referenceState: 'no_horizontal_overflow',
              source:
                  'docs/planning/v1.2/sprint_115_desktop_tablet_adaptation.json',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(
        report.violations,
        contains('responsive_claims_observation_without_release:overflow'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'scaling_issue',
            _entry(
              signal: 'scaling_issue',
              referenceState: 'SOMETHING_ELSE',
              source:
                  'docs/planning/v1.2/sprint_115_responsive_grid_system.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(
        report.violations,
        contains('entry_unknown_reference_state:scaling_issue:SOMETHING_ELSE'),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'chart_issue',
            _entry(
              signal: 'chart_issue',
              referenceState: 'chart_alternatives',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:chart_issue:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'overflow',
            _entry(signal: 'overflow', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:overflow'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'layout_shift',
            _entry(
              signal: 'layout_shift',
              referenceState: 'no_overlap',
              source:
                  'docs/planning/v1.2/sprint_115_wide_desktop_visual_implementation.json',
              limitations: const <String>[],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(report.violations, contains('entry_no_limitations:layout_shift'));
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'clipping',
            _entry(
              signal: 'clipping',
              referenceState: 'no_clipped_content',
              source: 'docs/planning/v1.2/sprint_115_mobile_adaptation.json',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:clipping:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'scaling_issue',
            _entry(
              signal: 'scaling_issue',
              referenceState: 'breakpoints',
              source:
                  'docs/planning/v1.2/sprint_115_responsive_grid_system.json',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:scaling_issue:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118ResponsiveUiHealthEntry>[
        ...Sprint118ResponsiveUiHealthContract.canonicalReview.entries,
        _entry(signal: 'overflow'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(report.violations, contains('signal_duplicate:overflow'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118ResponsiveUiHealthEntry>[
        for (final e
            in Sprint118ResponsiveUiHealthContract.canonicalReview.entries)
          if (e.signal != 'scaling_issue') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(report.violations, contains('signal_missing:scaling_issue'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'overflow',
            _entry(signal: 'unknown_signal', referenceState: 'no_overlap'),
          ),
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      // The replacement also removes the real 'overflow' entry, so both the
      // unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:overflow'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_115_desktop_tablet_adaptation.json',
          ],
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessGridSystemViewports: const <String>[],
          witnessWideDesktopAcceptance: const <String>[],
          witnessDesktopTabletAcceptance: const <String>[],
          witnessMobileAcceptance: const <String>[],
          witnessBrandVisualAcceptance: const <String>[],
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.blocked);
      expect(
        report.blockers,
        contains('upstream_responsive_vocabulary_missing'),
      );
    });

    test('records an open item when a signal carries no_reference_state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'scaling_issue',
            _entry(
              signal: 'scaling_issue',
              referenceState:
                  Sprint118ResponsiveUiHealthContract.noReferenceState,
              source:
                  'docs/planning/v1.2/sprint_115_responsive_grid_system.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ResponsiveUiHealthState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:scaling_issue'),
      );
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118ResponsiveUiHealthContract.sourceFor('overflow'),
        'docs/planning/v1.2/sprint_115_desktop_tablet_adaptation.json',
      );
      expect(
        Sprint118ResponsiveUiHealthContract.sourceFor('scaling_issue'),
        'docs/planning/v1.2/sprint_115_responsive_grid_system.json',
      );
      expect(Sprint118ResponsiveUiHealthContract.sourceFor('unknown'), '');
    });
  });
}
