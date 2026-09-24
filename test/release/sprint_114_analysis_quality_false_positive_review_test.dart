/// Test for Analysis Quality & False-Positive Review (Step 114.24).
///
/// Validates the six canonical dimensions — useful_warning, false_positive,
/// false_negative_reports, explanation_quality, dismissal_use, disabled_rules
/// — the blocked/fail/pass state of the review report, the seven-category
/// coverage contract (contradiction, pov, pacing, continuity, economy, power,
/// anachronism), the three cross-dimension honesty rules, explanation-quality
/// level validation, and the step manifest.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/analysis_quality_false_positive_review.dart';

const String _manifestPath =
    'docs/planning/v1.2/sprint_114_analysis_quality_false_positive_review.json';

AnalysisQualityEntry _entry(
  String category, {
  bool? usefulWarning = true,
  bool? falsePositive = false,
  List<String>? falseNegativeReports,
  String? explanationQuality = 'adequate',
  bool? dismissalUse = false,
  List<String>? disabledRules,
}) {
  return AnalysisQualityEntry(
    category: category,
    usefulWarning: usefulWarning,
    falsePositive: falsePositive,
    falseNegativeReports: falseNegativeReports ?? <String>[],
    explanationQuality: explanationQuality,
    dismissalUse: dismissalUse,
    disabledRules: disabledRules ?? <String>[],
  );
}

List<AnalysisQualityEntry> _fullSet() {
  return <AnalysisQualityEntry>[
    for (final id in AnalysisQualityFalsePositiveReview.expectedCategories)
      _entry(id),
  ];
}

void main() {
  group('114.24 Analysis Quality & False-Positive Review', () {
    test('six canonical dimensions in contract order', () {
      expect(AnalysisQualityEntry.requiredDimensions, <String>[
        'useful_warning',
        'false_positive',
        'false_negative_reports',
        'explanation_quality',
        'dismissal_use',
        'disabled_rules',
      ]);
    });

    test('seven canonical categories in contract order', () {
      expect(AnalysisQualityFalsePositiveReview.expectedCategories, <String>[
        'contradiction',
        'pov',
        'pacing',
        'continuity',
        'economy',
        'power',
        'anachronism',
      ]);
    });

    test('canonical explanation quality levels in contract order', () {
      expect(
        AnalysisQualityFalsePositiveReview.explanationQualityLevels,
        <String>['clear', 'adequate', 'unclear', 'absent'],
      );
    });

    test('absent entries are blocked without analysis claims', () {
      final report = AnalysisQualityFalsePositiveReview().evaluate(null);

      expect(report.state, AnalysisQualityState.blocked);
      expect(report.entries, isEmpty);
      expect(report.categoryCount, 0);
      expect(report.missingDimensions, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes.join(' '), contains('DEFERRED-EXTERNAL'));
      expect(
        report.notes.join(' '),
        contains('DISABLED-BY-CONTRACT'),
        reason: 'automatic creative-content upload stays disabled by contract',
      );
    });

    test('complete entry has no missing dimension', () {
      final review = AnalysisQualityFalsePositiveReview();
      expect(review.missingDimensions(_entry('contradiction')), isEmpty);
    });

    test('blank and absent dimensions are reported by canonical name', () {
      const bare = AnalysisQualityEntry(
        category: '',
        usefulWarning: null,
        falsePositive: null,
        falseNegativeReports: null,
        explanationQuality: null,
        dismissalUse: null,
        disabledRules: null,
      );
      expect(
        AnalysisQualityFalsePositiveReview().missingDimensions(bare),
        <String>[
          'category',
          'useful_warning',
          'false_positive',
          'false_negative_reports',
          'explanation_quality',
          'dismissal_use',
          'disabled_rules',
        ],
      );
    });

    test(
      'empty report lists are recorded answers, absent fields are missing',
      () {
        final review = AnalysisQualityFalsePositiveReview();
        final complete = _entry('pov');
        expect(review.missingDimensions(complete), isEmpty);
        const withoutFields = AnalysisQualityEntry(
          category: 'pov',
          usefulWarning: true,
          falsePositive: false,
          falseNegativeReports: null,
          explanationQuality: 'clear',
          dismissalUse: false,
          disabledRules: null,
        );
        expect(review.missingDimensions(withoutFields), <String>[
          'false_negative_reports',
          'disabled_rules',
        ]);
      },
    );

    test('coverage incomplete fails naming the missing categories', () {
      final report = AnalysisQualityFalsePositiveReview().evaluate(
        <AnalysisQualityEntry>[_entry('contradiction'), _entry('pov')],
      );
      expect(report.state, AnalysisQualityState.fail);
      expect(report.violations.join(' '), contains('coverage incomplete'));
      expect(report.violations.join(' '), contains('missing pacing'));
    });

    test('duplicate category entry fails', () {
      final entries = _fullSet();
      entries[1] = _entry('contradiction');
      final report = AnalysisQualityFalsePositiveReview().evaluate(entries);
      expect(report.state, AnalysisQualityState.fail);
      expect(
        report.violations.join(' '),
        contains('duplicate category: contradiction'),
      );
    });

    test('unexpected category entry is rejected', () {
      final report = AnalysisQualityFalsePositiveReview().evaluate(
        <AnalysisQualityEntry>[..._fullSet(), _entry('metaverse')],
      );
      expect(report.state, AnalysisQualityState.fail);
      expect(
        report.violations.join(' '),
        contains('unexpected category: metaverse'),
      );
    });

    test('false positive with no dismissal and no disabled rule fails', () {
      final entries = _fullSet();
      entries[0] = _entry('contradiction', falsePositive: true);
      final report = AnalysisQualityFalsePositiveReview().evaluate(entries);
      expect(report.state, AnalysisQualityState.fail);
      expect(
        report.violations,
        contains('false_positive_unaddressed: contradiction'),
      );
    });

    test('false positive addressed by dismissal passes without penalty', () {
      final entries = _fullSet();
      entries[0] = _entry(
        'contradiction',
        falsePositive: true,
        dismissalUse: true,
      );
      final report = AnalysisQualityFalsePositiveReview().evaluate(entries);
      expect(report.state, AnalysisQualityState.pass);
      expect(report.violations, isEmpty);
    });

    test('false positive addressed by disabling the rule passes', () {
      final entries = _fullSet();
      entries[1] = _entry(
        'pov',
        usefulWarning: false,
        falsePositive: true,
        disabledRules: <String>['pov'],
      );
      final report = AnalysisQualityFalsePositiveReview().evaluate(entries);
      expect(report.state, AnalysisQualityState.pass);
      expect(report.violations, isEmpty);
    });

    test('disabled rule without recorded false positive fails', () {
      final entries = _fullSet();
      entries[2] = _entry('pacing', disabledRules: <String>['pacing']);
      final report = AnalysisQualityFalsePositiveReview().evaluate(entries);
      expect(report.state, AnalysisQualityState.fail);
      expect(
        report.violations,
        contains('disabled_without_false_positive: pacing'),
      );
    });

    test('dismissal recorded without false positive fails', () {
      final entries = _fullSet();
      entries[3] = _entry('continuity', dismissalUse: true);
      final report = AnalysisQualityFalsePositiveReview().evaluate(entries);
      expect(report.state, AnalysisQualityState.fail);
      expect(
        report.violations,
        contains('dismissal_without_false_positive: continuity'),
      );
    });

    test('explanation quality outside canonical levels fails', () {
      final entries = _fullSet();
      entries[4] = _entry('economy', explanationQuality: 'vibes');
      final report = AnalysisQualityFalsePositiveReview().evaluate(entries);
      expect(report.state, AnalysisQualityState.fail);
      expect(
        report.violations.join(' '),
        contains('unexpected explanation_quality: vibes'),
      );
    });

    test('full seven-category review passes and retains every answer', () {
      final report = AnalysisQualityFalsePositiveReview().evaluate(_fullSet());
      expect(report.state, AnalysisQualityState.pass);
      expect(report.categoryCount, 7);
      expect(report.missingDimensions, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes.join(' '), contains('DEFERRED-EXTERNAL'));
      expect(
        report.entries.every(
          (e) => e.falseNegativeReports != null && e.disabledRules != null,
        ),
        isTrue,
        reason: 'every category records its report and disabled-rule answers',
      );
    });

    test('manifest declares canonical dimensions, rules, and deferrals', () {
      final file = File(_manifestPath);
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.24');
      expect(document['dimensions'], <dynamic>[
        'useful_warning',
        'false_positive',
        'false_negative_reports',
        'explanation_quality',
        'dismissal_use',
        'disabled_rules',
      ]);
      expect(document['categories'], <dynamic>[
        'contradiction',
        'pov',
        'pacing',
        'continuity',
        'economy',
        'power',
        'anachronism',
      ]);
      expect(document['explanation_quality_levels'], <dynamic>[
        'clear',
        'adequate',
        'unclear',
        'absent',
      ]);
      expect(document['violations'], <dynamic>[
        'false_positive_unaddressed',
        'disabled_without_false_positive',
        'dismissal_without_false_positive',
      ]);
      expect(
        document['automatic_creative_content_upload'],
        'DISABLED-BY-CONTRACT',
      );
      expect(document['native_analysis_session'], 'DEFERRED-EXTERNAL');
      expect(document['end_user_validation'], 'DEFERRED-EXTERNAL');
      expect(document['public_distribution_gates'], 'DEFERRED-EXTERNAL');
      expect(document['limitations'], isA<List<dynamic>>());
      expect((document['limitations'] as List<dynamic>), isNotEmpty);
    });
  });
}
