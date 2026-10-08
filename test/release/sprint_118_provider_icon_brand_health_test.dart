import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_provider_icon_brand_health.dart';

/// A single icon & brand health entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ProviderIconBrandHealthEntry _entry({
  String signal = 'missing_asset',
  String referenceState = 'fallback_icon',
  String source = 'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118ProviderIconBrandHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118ProviderIconBrandHealthReview _review({
  String releaseState =
      Sprint118ProviderIconBrandHealthContract.delayedReleaseState,
  List<Sprint118ProviderIconBrandHealthEntry>? entries,
}) {
  return Sprint118ProviderIconBrandHealthReview(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118ProviderIconBrandHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118ProviderIconBrandHealthEntry> _replacing(
  String signal,
  Sprint118ProviderIconBrandHealthEntry replacement,
) {
  return <Sprint118ProviderIconBrandHealthEntry>[
    for (final e
        in Sprint118ProviderIconBrandHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118ProviderIconBrandHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118ProviderIconBrandHealthContract.requiredBaselineVerdict,
  String releaseState =
      Sprint118ProviderIconBrandHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ProviderIconBrandHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118ProviderIconBrandHealthContract.charterWindowMinutes,
  List<String>? witnessIconRegistryFields,
  List<String>? witnessIconRegistryAcceptance,
  List<String>? witnessBrandCertificationFields,
  List<String>? witnessBrandVisualAcceptance,
  List<String>? readableSources,
}) {
  return Sprint118ProviderIconBrandHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessIconRegistryFields:
        witnessIconRegistryFields ??
        const <String>[
          'provider_id',
          'display_name',
          'category',
          'asset_light',
          'asset_dark',
          'monochrome_fallback',
          'trademark_notice',
          'asset_version',
        ],
    witnessIconRegistryAcceptance:
        witnessIconRegistryAcceptance ??
        const <String>[
          'provider_id_lookup',
          'official_asset_policy',
          'aspect_ratio',
          'fallback_icon',
          'accessible_name',
          'asset_version',
        ],
    witnessBrandCertificationFields:
        witnessBrandCertificationFields ??
        const <String>[
          'provider_id',
          'asset_source',
          'license_or_permission',
          'asset_version',
          'theme_variants',
          'fallback',
          'accessible_name',
          'review_status',
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
        readableSources ??
        Sprint118ProviderIconBrandHealthContract.canonicalSources,
  );
}

Sprint118ProviderIconBrandHealthReport _run(
  Sprint118ProviderIconBrandHealthReview review, {
  Sprint118ProviderIconBrandHealthAnchor? anchor,
}) {
  return const Sprint118ProviderIconBrandHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.13 Provider Icon & Brand Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118ProviderIconBrandHealthContract.canonicalStep, '118.13');
      expect(
        Sprint118ProviderIconBrandHealthContract.title,
        'Provider Icon & Brand Health',
      );
      expect(
        Sprint118ProviderIconBrandHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_provider_icon_brand_health.json',
      );
      expect(Sprint118ProviderIconBrandHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118ProviderIconBrandHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118ProviderIconBrandHealthContract.requiredFields.length, 5);
      expect(
        Sprint118ProviderIconBrandHealthContract.iconBrandSignals.length,
        6,
      );
      expect(
        Sprint118ProviderIconBrandHealthContract.canonicalSources.length,
        6,
      );
      // Every canonical signal maps to a committed evidence source.
      for (final s
          in Sprint118ProviderIconBrandHealthContract.iconBrandSignals) {
        expect(
          Sprint118ProviderIconBrandHealthContract.sourceFor(s),
          isNotEmpty,
        );
      }
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118ProviderIconBrandHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['asset_version', 'asset_light'],
          <String>['fallback_icon', 'aspect_ratio'],
          <String>['theme_variants', 'fallback'],
          <String>['icon_review', 'fallbacks'],
        ],
      );
      expect(vocab, <String>[
        'asset_version',
        'asset_light',
        'fallback_icon',
        'aspect_ratio',
        'theme_variants',
        'fallback',
        'icon_review',
        'fallbacks',
      ]);
    });

    test('canonical review covers the six signals and claims no live '
        'observation', () {
      final review = Sprint118ProviderIconBrandHealthContract.canonicalReview;
      expect(review.signals.length, 6);
      expect(review.signals.toSet(), <String>{
        'missing_asset',
        'outdated_asset',
        'theme_variant',
        'distortion',
        'accessible_name',
        'brand_issue',
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
      expect(report.state, Sprint118ProviderIconBrandHealthState.pass);
      expect(report.verdict, 'PROVIDER_ICON_BRAND_HEALTH_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 6);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      // The brand_issue signal has no witness state; the gate records that
      // upstream gap as an open item rather than a violation.
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:brand_issue'),
      );
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ProviderIconBrandHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_PROVIDER_ICON_BRAND_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_provider_icon_brand_health_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.blocked);
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
      expect(report.state, Sprint118ProviderIconBrandHealthState.blocked);
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
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'missing_asset',
            _entry(
              signal: 'missing_asset',
              referenceState: 'fallback_icon',
              source:
                  'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations,
        contains('icon_brand_claims_observation_without_release:missing_asset'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'theme_variant',
            _entry(
              signal: 'theme_variant',
              referenceState: 'SOMETHING_ELSE',
              source:
                  'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations,
        contains('entry_unknown_reference_state:theme_variant:SOMETHING_ELSE'),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'accessible_name',
            _entry(
              signal: 'accessible_name',
              referenceState: 'accessible_name',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:accessible_name:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'missing_asset',
            _entry(signal: 'missing_asset', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:missing_asset'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'outdated_asset',
            _entry(
              signal: 'outdated_asset',
              referenceState: 'asset_version',
              source:
                  'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
              limitations: const <String>[],
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations,
        contains('entry_no_limitations:outdated_asset'),
      );
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'distortion',
            _entry(
              signal: 'distortion',
              referenceState: 'aspect_ratio',
              source:
                  'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:distortion:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'accessible_name',
            _entry(
              signal: 'accessible_name',
              referenceState: 'accessible_name',
              source:
                  'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:accessible_name:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118ProviderIconBrandHealthEntry>[
        ...Sprint118ProviderIconBrandHealthContract.canonicalReview.entries,
        _entry(signal: 'missing_asset'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(report.violations, contains('signal_duplicate:missing_asset'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118ProviderIconBrandHealthEntry>[
        for (final e
            in Sprint118ProviderIconBrandHealthContract.canonicalReview.entries)
          if (e.signal != 'brand_issue') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(report.violations, contains('signal_missing:brand_issue'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'missing_asset',
            _entry(signal: 'unknown_signal', referenceState: 'fallback_icon'),
          ),
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      // The replacement also removes the real 'missing_asset' entry, so both the
      // unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:missing_asset'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
          ],
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessIconRegistryFields: const <String>[],
          witnessIconRegistryAcceptance: const <String>[],
          witnessBrandCertificationFields: const <String>[],
          witnessBrandVisualAcceptance: const <String>[],
        ),
      );
      expect(report.state, Sprint118ProviderIconBrandHealthState.blocked);
      expect(
        report.blockers,
        contains('upstream_icon_brand_vocabulary_missing'),
      );
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118ProviderIconBrandHealthContract.sourceFor('missing_asset'),
        'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
      );
      expect(
        Sprint118ProviderIconBrandHealthContract.sourceFor('brand_issue'),
        'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
      );
      expect(Sprint118ProviderIconBrandHealthContract.sourceFor('unknown'), '');
    });
  });
}
