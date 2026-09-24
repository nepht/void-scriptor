/// Feature availability reconciliation contract for Sprint 114.22.
///
/// Dependency-free model that compares flag, entitlement, documentation,
/// actual availability, and known issues across the 29 unique features
/// F1-F29. Every entry carries seven canonical required fields; blank
/// strings, null flags, and empty evidence lists are reported as missing by
/// canonical wire name, while an empty known_issues list is a recorded
/// answer ("no known issue"), not a missing field. Coverage must be exactly
/// F1-F29 once each: F30 is an alias of F24 and never a separate entry.
///
/// Two cross-field honesty rules run on top of coverage: a feature claimed
/// available must also be documented (availability without documentation is
/// a reconciliation failure), and a feature not available must carry a
/// recorded known issue explaining why (silent unavailability fails). An
/// absent entry set stays BLOCKED without availability claims.
///
/// Availability here means implementation and test paths resolve at HEAD
/// and the flag is traceable to its source; every flag defaults OFF, so this
/// is not a runtime-on claim. Native runtime verification, marketplace
/// entitlement verification, and public distribution remain external gates
/// and are not claimed by this model.
class FeatureAvailabilityEntry {
  const FeatureAvailabilityEntry({
    required this.feature,
    required this.flag,
    required this.entitlement,
    required this.documented,
    required this.available,
    required this.knownIssues,
    required this.evidence,
  });

  static const List<String> requiredFieldNames = <String>[
    'feature',
    'flag',
    'entitlement',
    'documented',
    'available',
    'known_issues',
    'evidence',
  ];

  final String feature;
  final String flag;
  final String entitlement;
  final bool? documented;
  final bool? available;
  final List<String>? knownIssues;
  final List<String>? evidence;
}

enum FeatureAvailabilityState { pass, fail, blocked }

class FeatureAvailabilityReport {
  const FeatureAvailabilityReport({
    required this.state,
    required this.entries,
    required this.featureCount,
    required this.missingFields,
    required this.violations,
    required this.notes,
  });

  final FeatureAvailabilityState state;
  final List<FeatureAvailabilityEntry> entries;
  final int featureCount;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> notes;
}

class FeatureAvailabilityReconciliation {
  static const List<String> expectedFeatureIds = <String>[
    'F1',
    'F2',
    'F3',
    'F4',
    'F5',
    'F6',
    'F7',
    'F8',
    'F9',
    'F10',
    'F11',
    'F12',
    'F13',
    'F14',
    'F15',
    'F16',
    'F17',
    'F18',
    'F19',
    'F20',
    'F21',
    'F22',
    'F23',
    'F24',
    'F25',
    'F26',
    'F27',
    'F28',
    'F29',
  ];

  /// Canonical-order missing fields for a single entry. Blank [feature],
  /// [flag], or [entitlement] strings, null [documented]/[available] values,
  /// null [knownIssues], and null or empty [evidence] are each reported by
  /// wire name; a non-null empty [knownIssues] list is a recorded answer.
  List<String> missingFields(FeatureAvailabilityEntry entry) {
    final missing = <String>[];
    if (entry.feature.trim().isEmpty) {
      missing.add('feature');
    }
    if (entry.flag.trim().isEmpty) {
      missing.add('flag');
    }
    if (entry.entitlement.trim().isEmpty) {
      missing.add('entitlement');
    }
    if (entry.documented == null) {
      missing.add('documented');
    }
    if (entry.available == null) {
      missing.add('available');
    }
    if (entry.knownIssues == null) {
      missing.add('known_issues');
    }
    if (entry.evidence == null || entry.evidence!.isEmpty) {
      missing.add('evidence');
    }
    return missing;
  }

  FeatureAvailabilityReport evaluate(List<FeatureAvailabilityEntry>? entries) {
    if (entries == null || entries.isEmpty) {
      return const FeatureAvailabilityReport(
        state: FeatureAvailabilityState.blocked,
        entries: <FeatureAvailabilityEntry>[],
        featureCount: 0,
        missingFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada entri rekonsiliasi ketersediaan fitur; tidak ada klaim '
              'ketersediaan; verifikasi runtime native, entitlement '
              'marketplace, dan publikasi distribusi DEFERRED-EXTERNAL.',
        ],
      );
    }

    final missing = <String>{};
    final violations = <String>[];
    final seen = <String>{};

    for (final entry in entries) {
      missing.addAll(missingFields(entry));
      final id = entry.feature.trim();
      if (id.isNotEmpty) {
        if (!expectedFeatureIds.contains(id)) {
          violations.add('unexpected feature id: $id');
        } else if (!seen.add(id)) {
          violations.add('duplicate feature: $id');
        }
      }
    }

    if (missing.isEmpty) {
      final missingFeatures = <String>[
        for (final id in expectedFeatureIds)
          if (!seen.contains(id)) id,
      ];
      if (missingFeatures.isNotEmpty) {
        violations.add(
          'coverage incomplete: missing ${missingFeatures.join(', ')}',
        );
      }

      for (final entry in entries) {
        final id = entry.feature.trim();
        if (!expectedFeatureIds.contains(id) || !seen.contains(id)) {
          continue;
        }
        if (entry.available == true && entry.documented == false) {
          violations.add('available_undocumented: $id');
        }
        if (entry.available == false &&
            (entry.knownIssues == null || entry.knownIssues!.isEmpty)) {
          violations.add('unavailable_without_known_issue: $id');
        }
      }
    }

    return FeatureAvailabilityReport(
      state: violations.isEmpty
          ? FeatureAvailabilityState.pass
          : FeatureAvailabilityState.fail,
      entries: List<FeatureAvailabilityEntry>.unmodifiable(entries),
      featureCount: entries.length,
      missingFields: List<String>.unmodifiable(
        missing.toList()..sort(
          (a, b) => FeatureAvailabilityEntry.requiredFieldNames
              .indexOf(a)
              .compareTo(
                FeatureAvailabilityEntry.requiredFieldNames.indexOf(b),
              ),
        ),
      ),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Rekonsiliasi lokal flag/entitlement/dokumentasi/ketersediaan atas '
            '29 fitur kanonik; verifikasi runtime native, entitlement '
            'marketplace, dan publikasi distribusi DEFERRED-EXTERNAL.',
      ],
    );
  }
}
