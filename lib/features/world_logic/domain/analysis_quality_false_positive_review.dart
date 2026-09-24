/// Analysis quality & false-positive review contract for Sprint 114.24.
///
/// Dependency-free model that judges the quality of contradiction, POV,
/// pacing, continuity, economy, power, and anachronism warnings without
/// reading, sending, or uploading any creative content — automatic
/// creative-content upload is disabled by contract. Every entry carries
/// six canonical dimensions — useful_warning, false_positive,
/// false_negative_reports, explanation_quality, dismissal_use,
/// disabled_rules; absent values are reported by canonical wire name,
/// while empty report and disabled-rule lists are recorded answers
/// ("none recorded"), not missing fields. Coverage must be exactly the
/// seven canonical categories once each, and explanation_quality must be
/// one of the canonical levels clear | adequate | unclear | absent.
///
/// Three cross-dimension honesty rules run on top of coverage: a recorded
/// false positive must show a recorded response — dismissal or a disabled
/// rule (silent unaddressed false positives fail), a disabled rule must be
/// justified by a recorded false positive, and a recorded dismissal must
/// be justified by a recorded false positive. An absent entry set stays
/// BLOCKED without analysis-quality claims.
///
/// Outcomes here are judged from recorded review entries, not from live
/// native analysis sessions. Native analysis sessions, end-user
/// validation, and public distribution remain external gates and are not
/// claimed by this model.
class AnalysisQualityEntry {
  const AnalysisQualityEntry({
    required this.category,
    required this.usefulWarning,
    required this.falsePositive,
    required this.falseNegativeReports,
    required this.explanationQuality,
    required this.dismissalUse,
    required this.disabledRules,
  });

  static const List<String> requiredDimensions = <String>[
    'useful_warning',
    'false_positive',
    'false_negative_reports',
    'explanation_quality',
    'dismissal_use',
    'disabled_rules',
  ];

  /// Warning category identity reported alongside the dimensions when
  /// blank.
  final String category;
  final bool? usefulWarning;
  final bool? falsePositive;
  final List<String>? falseNegativeReports;
  final String? explanationQuality;
  final bool? dismissalUse;
  final List<String>? disabledRules;
}

enum AnalysisQualityState { pass, fail, blocked }

class AnalysisQualityReport {
  const AnalysisQualityReport({
    required this.state,
    required this.entries,
    required this.categoryCount,
    required this.missingDimensions,
    required this.violations,
    required this.notes,
  });

  final AnalysisQualityState state;
  final List<AnalysisQualityEntry> entries;
  final int categoryCount;
  final List<String> missingDimensions;
  final List<String> violations;
  final List<String> notes;
}

class AnalysisQualityFalsePositiveReview {
  static const List<String> expectedCategories = <String>[
    'contradiction',
    'pov',
    'pacing',
    'continuity',
    'economy',
    'power',
    'anachronism',
  ];

  static const List<String> explanationQualityLevels = <String>[
    'clear',
    'adequate',
    'unclear',
    'absent',
  ];

  /// Canonical-order missing dimensions for a single entry. A blank
  /// [AnalysisQualityEntry.category] string, null scalar dimensions, null
  /// or blank [AnalysisQualityEntry.explanationQuality], and null list
  /// dimensions are each reported by wire name; non-null empty
  /// [AnalysisQualityEntry.falseNegativeReports] and
  /// [AnalysisQualityEntry.disabledRules] lists are recorded answers.
  List<String> missingDimensions(AnalysisQualityEntry entry) {
    final missing = <String>[];
    if (entry.category.trim().isEmpty) {
      missing.add('category');
    }
    if (entry.usefulWarning == null) {
      missing.add('useful_warning');
    }
    if (entry.falsePositive == null) {
      missing.add('false_positive');
    }
    if (entry.falseNegativeReports == null) {
      missing.add('false_negative_reports');
    }
    if (entry.explanationQuality == null ||
        entry.explanationQuality!.trim().isEmpty) {
      missing.add('explanation_quality');
    }
    if (entry.dismissalUse == null) {
      missing.add('dismissal_use');
    }
    if (entry.disabledRules == null) {
      missing.add('disabled_rules');
    }
    return missing;
  }

  AnalysisQualityReport evaluate(List<AnalysisQualityEntry>? entries) {
    if (entries == null || entries.isEmpty) {
      return const AnalysisQualityReport(
        state: AnalysisQualityState.blocked,
        entries: <AnalysisQualityEntry>[],
        categoryCount: 0,
        missingDimensions: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada entri review kualitas analisis; tidak ada klaim '
              'kualitas peringatan; unggahan isi kreatif otomatis '
              'DISABLED-BY-CONTRACT; sesi analisis native, validasi '
              'end-user, dan publikasi distribusi DEFERRED-EXTERNAL.',
        ],
      );
    }

    final missing = <String>{};
    final violations = <String>[];
    final seen = <String>{};

    for (final entry in entries) {
      missing.addAll(missingDimensions(entry));
      final id = entry.category.trim();
      if (id.isNotEmpty) {
        if (!expectedCategories.contains(id)) {
          violations.add('unexpected category: $id');
        } else if (!seen.add(id)) {
          violations.add('duplicate category: $id');
        }
      }
    }

    if (missing.isEmpty) {
      final missingCategories = <String>[
        for (final id in expectedCategories)
          if (!seen.contains(id)) id,
      ];
      if (missingCategories.isNotEmpty) {
        violations.add(
          'coverage incomplete: missing ${missingCategories.join(', ')}',
        );
      }

      for (final entry in entries) {
        final id = entry.category.trim();
        if (!expectedCategories.contains(id) || !seen.contains(id)) {
          continue;
        }
        final level = entry.explanationQuality!.trim();
        if (!explanationQualityLevels.contains(level)) {
          violations.add('unexpected explanation_quality: $level');
        }
        final falsePositive = entry.falsePositive == true;
        final dismissed = entry.dismissalUse == true;
        final disabled =
            entry.disabledRules != null && entry.disabledRules!.isNotEmpty;
        if (falsePositive && !dismissed && !disabled) {
          violations.add('false_positive_unaddressed: $id');
        }
        if (disabled && !falsePositive) {
          violations.add('disabled_without_false_positive: $id');
        }
        if (dismissed && !falsePositive) {
          violations.add('dismissal_without_false_positive: $id');
        }
      }
    }

    return AnalysisQualityReport(
      state: missing.isEmpty && violations.isEmpty
          ? AnalysisQualityState.pass
          : AnalysisQualityState.fail,
      entries: List<AnalysisQualityEntry>.unmodifiable(entries),
      categoryCount: entries.length,
      missingDimensions: List<String>.unmodifiable(
        missing.toList()..sort((a, b) {
          const order = <String>[
            'category',
            ...AnalysisQualityEntry.requiredDimensions,
          ];
          return order.indexOf(a).compareTo(order.indexOf(b));
        }),
      ),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Review lokal kualitas peringatan analisis atas entri tercatat '
            'tanpa membaca atau mengunggah isi kreatif; unggahan isi '
            'kreatif otomatis DISABLED-BY-CONTRACT; sesi analisis native, '
            'validasi end-user, dan publikasi distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
