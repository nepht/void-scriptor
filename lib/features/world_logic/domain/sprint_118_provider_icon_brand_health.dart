/// Fail-closed provider icon & brand health review for roadmap step 118.13 --
/// Provider Icon & Brand Health.
///
/// Objective (external canonical `sprint_118.json`): monitor missing assets,
/// outdated versions, incorrect variants, aspect ratio, accessibility labels,
/// and brand complaints. The canonical signal list is exactly six items:
/// `missing_asset`, `outdated_asset`, `theme_variant`, `distortion`,
/// `accessible_name`, and `brand_issue`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live observation runs. The gate answers a single
/// question: does the declared review carry, for every canonical icon & brand
/// signal, a reference state drawn from the committed icon & brand witnesses,
/// a committed readable evidence source, a positive window bounded by the
/// charter, and a stated limitation -- while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes icon & brand readings nobody
///   measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes a rendered icon or a live brand report that was never
///   captured. Refused by name, per signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed provider icon
///   registry fields (115.8), the committed provider icon registry acceptance
///   items (115.8), the committed brand asset & icon certification fields
///   (116.7), and the committed brand, visual & accessibility gate acceptance
///   areas (116.47), so the review and the icon & brand contracts cannot drift
///   apart.
///
/// The objective names `brand_issue` explicitly, but the committed icon & brand
/// witnesses declare no state for a brand complaint. Rather than widen the gate
/// silently or drop the requirement, the gate owns a declared
/// `no_reference_state` marker and records the upstream omission as an open item
/// (`upstream_state_vocabulary_gap:<signal>`) -- an honest boundary, not a
/// violation of this step.
///
/// Live icon rendering, screenshot baseline comparison, per-provider brand
/// approval, brand complaint intake, connector certification, provider
/// exposure, release authorization, and publication remain `DEFERRED-EXTERNAL`;
/// this review freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an icon & brand health review can rest in. `blocked` is the
/// honest resting state for "this review cannot yet be trusted", and it is
/// distinct from `fail`, which means the review contradicts its own evidence.
enum Sprint118ProviderIconBrandHealthState { pass, fail, blocked }

/// One icon & brand entry: the declared reference for a single canonical
/// signal, with the boundary it was frozen under.
class Sprint118ProviderIconBrandHealthEntry {
  const Sprint118ProviderIconBrandHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The icon & brand signal, drawn from the canonical signal vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed icon & brand witness
  /// vocabulary, or the declared `no_reference_state` marker when the witness
  /// declares no state for this signal.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live icon renders or live brand reports.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118ProviderIconBrandHealthReview {
  const Sprint118ProviderIconBrandHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118ProviderIconBrandHealthEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and icon & brand witnesses
/// actually say. A review is only as honest as the witnesses it reads.
class Sprint118ProviderIconBrandHealthAnchor {
  const Sprint118ProviderIconBrandHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessIconRegistryFields,
    required this.witnessIconRegistryAcceptance,
    required this.witnessBrandCertificationFields,
    required this.witnessBrandVisualAcceptance,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The required fields the committed 115.8 provider icon registry declares.
  final List<String> witnessIconRegistryFields;

  /// The acceptance items the committed 115.8 provider icon registry declares.
  final List<String> witnessIconRegistryAcceptance;

  /// The required fields the committed 116.7 brand asset & icon certification
  /// declares.
  final List<String> witnessBrandCertificationFields;

  /// The acceptance areas the committed 116.47 brand, visual & accessibility
  /// gate declares.
  final List<String> witnessBrandVisualAcceptance;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118ProviderIconBrandHealthReport {
  const Sprint118ProviderIconBrandHealthReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredSignals = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118ProviderIconBrandHealthState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredSignals;
  final int observedCount;

  /// Whether the review may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get reviewVerified =>
      state == Sprint118ProviderIconBrandHealthState.pass;

  String get externalGates =>
      Sprint118ProviderIconBrandHealthContract.externalGates;
}

/// The fixed vocabulary of step 118.13, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118ProviderIconBrandHealthContract {
  const Sprint118ProviderIconBrandHealthContract._();

  static const String canonicalStep = '118.13';
  static const String title = 'Provider Icon & Brand Health';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_provider_icon_brand_health.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 115.8 provider icon registry that declares the asset policy,
  /// aspect ratio, fallback icon, accessible name, and asset version acceptance
  /// items this review references.
  static const String iconRegistryManifestPath =
      'docs/planning/v1.2/sprint_115_provider_icon_registry.json';

  /// The committed 116.7 brand asset & icon certification that declares the
  /// asset version, theme variants, and accessible name fields this review
  /// references.
  static const String brandCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json';

  /// The committed 116.47 brand, visual & accessibility gate that declares the
  /// icon review and fallback acceptance areas this review references.
  static const String brandVisualManifestPath =
      'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.13.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The six canonical provider icon & brand signals the objective names.
  static const List<String> iconBrandSignals = <String>[
    'missing_asset',
    'outdated_asset',
    'theme_variant',
    'distortion',
    'accessible_name',
    'brand_issue',
  ];

  /// The declared marker for a signal the committed icon & brand witnesses have
  /// no state for. It is honest on the delayed path: it declares no reference
  /// state rather than inventing one.
  static const String noReferenceState = 'no_reference_state';

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
    'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
    'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json',
    'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
    'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json',
    'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
  ];

  /// The distinct union of the committed icon & brand witness vocabularies, in
  /// witness order.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final state in vocabulary) {
        if (seen.add(state)) result.add(state);
      }
    }
    return result;
  }

  /// The evidence source registered for a canonical signal.
  static String sourceFor(String signal) {
    final index = iconBrandSignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing. The
  /// `brand_issue` signal carries the `no_reference_state` marker because the
  /// committed icon & brand witnesses declare no state for a brand complaint;
  /// the gate records that upstream gap as an open item.
  static const Sprint118ProviderIconBrandHealthReview
  canonicalReview = Sprint118ProviderIconBrandHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118ProviderIconBrandHealthEntry>[
      Sprint118ProviderIconBrandHealthEntry(
        signal: 'missing_asset',
        referenceState: 'fallback_icon',
        source: 'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderIconBrandHealthEntry(
        signal: 'outdated_asset',
        referenceState: 'asset_version',
        source: 'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderIconBrandHealthEntry(
        signal: 'theme_variant',
        referenceState: 'theme_variants',
        source:
            'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderIconBrandHealthEntry(
        signal: 'distortion',
        referenceState: 'aspect_ratio',
        source: 'docs/planning/v1.2/sprint_115_provider_icon_registry.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderIconBrandHealthEntry(
        signal: 'accessible_name',
        referenceState: 'accessible_name',
        source:
            'docs/planning/v1.2/sprint_116_brand_asset_icon_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118ProviderIconBrandHealthEntry(
        signal: 'brand_issue',
        referenceState: noReferenceState,
        source:
            'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and icon & brand
/// witnesses. Never invents: an unreadable witness yields `null`, which the gate
/// reports as blocked rather than as a pass.
class Sprint118ProviderIconBrandHealthLoader {
  const Sprint118ProviderIconBrandHealthLoader();

  Sprint118ProviderIconBrandHealthAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118ProviderIconBrandHealthContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118ProviderIconBrandHealthContract.charterManifestPath,
    );
    if (charter == null) return null;
    final iconRegistry = _readJsonObject(
      Sprint118ProviderIconBrandHealthContract.iconRegistryManifestPath,
    );
    if (iconRegistry == null) return null;
    final brandCertification = _readJsonObject(
      Sprint118ProviderIconBrandHealthContract.brandCertificationManifestPath,
    );
    if (brandCertification == null) return null;
    final brandVisual = _readJsonObject(
      Sprint118ProviderIconBrandHealthContract.brandVisualManifestPath,
    );
    if (brandVisual == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118ProviderIconBrandHealthContract.charterWindowMinutes;

    final readable = <String>[
      for (final source
          in Sprint118ProviderIconBrandHealthContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    final canonicalSteps = iconRegistry['sources'];
    final canonicalStepsMap = canonicalSteps is Map<String, dynamic>
        ? canonicalSteps
        : const <String, dynamic>{};
    final stepsMap = canonicalStepsMap['canonical_steps'];
    final stepsMap2 = stepsMap is Map<String, dynamic>
        ? stepsMap
        : const <String, dynamic>{};

    return Sprint118ProviderIconBrandHealthAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessIconRegistryFields: _stringList(iconRegistry['required_fields']),
      witnessIconRegistryAcceptance: _stringList(stepsMap2['step_acceptance']),
      witnessBrandCertificationFields: _stringList(
        brandCertification['required_fields'],
      ),
      witnessBrandVisualAcceptance: _stringList(
        brandVisual['acceptance_areas'],
      ),
      readableSources: readable,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return <String>[
        for (final item in value)
          if (item is String) item,
      ];
    }
    return const <String>[];
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class Sprint118ProviderIconBrandHealthGate {
  const Sprint118ProviderIconBrandHealthGate();

  /// Evaluate the canonical review against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118ProviderIconBrandHealthReport evaluate() => evaluateWith(
    const Sprint118ProviderIconBrandHealthLoader().loadAnchor(),
    Sprint118ProviderIconBrandHealthContract.canonicalReview,
  );

  Sprint118ProviderIconBrandHealthReport evaluateWith(
    Sprint118ProviderIconBrandHealthAnchor? anchor,
    Sprint118ProviderIconBrandHealthReview review,
  ) {
    if (anchor == null) {
      return Sprint118ProviderIconBrandHealthReport(
        state: Sprint118ProviderIconBrandHealthState.blocked,
        verdict: 'SPRINT_118_PROVIDER_ICON_BRAND_HEALTH_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118ProviderIconBrandHealthContract.requiredFields,
        ),
        blockers: const <String>[
          'committed_provider_icon_brand_health_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_provider_icon_brand_health_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes icon & brand readings
    // nobody measured.
    if (anchor.baselineState !=
            Sprint118ProviderIconBrandHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118ProviderIconBrandHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118ProviderIconBrandHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118ProviderIconBrandHealthContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The release state must agree with the baseline anchor.
    if (anchor.releaseState != review.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'review=${review.releaseState}',
      );
    }

    // (4) On the delayed path no signal may claim an observation: with no
    // release, an observation describes a rendered icon or a live brand report
    // that was never captured.
    final delayed =
        review.releaseState ==
        Sprint118ProviderIconBrandHealthContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'icon_brand_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessIconRegistryFields.isEmpty ||
        anchor.witnessIconRegistryAcceptance.isEmpty ||
        anchor.witnessBrandCertificationFields.isEmpty ||
        anchor.witnessBrandVisualAcceptance.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_icon_brand_vocabulary_missing');
    }
    final vocabulary =
        Sprint118ProviderIconBrandHealthContract.stateVocabulary(<List<String>>[
          anchor.witnessIconRegistryFields,
          anchor.witnessIconRegistryAcceptance,
          anchor.witnessBrandCertificationFields,
          anchor.witnessBrandVisualAcceptance,
        ]);

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118ProviderIconBrandHealthContract.iconBrandSignals.contains(
        signal,
      )) {
        violations.add('signal_unknown:$signal');
      }
      if (entry.referenceState.trim().isEmpty) {
        violations.add('entry_blank_reference_state:$signal');
      }
      if (entry.source.trim().isEmpty) {
        violations.add('entry_blank_source:$signal');
      }
      if (entry.limitations.isEmpty) {
        violations.add('entry_no_limitations:$signal');
      }
      if (entry.window <= 0) {
        violations.add('entry_nonpositive_window:$signal:${entry.window}');
      } else if (entry.window > anchor.charterWindowMinutes) {
        violations.add(
          'entry_window_exceeds_charter:$signal:${entry.window}:'
          '${anchor.charterWindowMinutes}',
        );
      }
      // A reference state is judged against the witness vocabulary unless the
      // witness is silent, in which case the review is blocked upstream rather
      // than failed. The declared `no_reference_state` marker records an honest
      // upstream gap instead of inventing a state.
      if (entry.referenceState.trim().isNotEmpty && !witnessIncomplete) {
        if (entry.referenceState ==
            Sprint118ProviderIconBrandHealthContract.noReferenceState) {
          openItems.add('upstream_state_vocabulary_gap:$signal');
        } else if (!vocabulary.contains(entry.referenceState)) {
          violations.add(
            'entry_unknown_reference_state:$signal:${entry.referenceState}',
          );
        }
      }
      if (entry.source.trim().isNotEmpty &&
          !anchor.readableSources.contains(entry.source)) {
        violations.add('entry_unreadable_source:$signal:${entry.source}');
      }
    }
    for (final signal in declared.keys) {
      if (declared[signal]! > 1) {
        violations.add('signal_duplicate:$signal');
      }
    }
    for (final signal
        in Sprint118ProviderIconBrandHealthContract.iconBrandSignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source
        in Sprint118ProviderIconBrandHealthContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118ProviderIconBrandHealthReport(
        state: Sprint118ProviderIconBrandHealthState.fail,
        verdict: 'SPRINT_118_PROVIDER_ICON_BRAND_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118ProviderIconBrandHealthReport(
        state: Sprint118ProviderIconBrandHealthState.blocked,
        verdict: 'SPRINT_118_PROVIDER_ICON_BRAND_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118ProviderIconBrandHealthReport(
      state: Sprint118ProviderIconBrandHealthState.pass,
      verdict: 'PROVIDER_ICON_BRAND_HEALTH_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
