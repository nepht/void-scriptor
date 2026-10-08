/// Fail-closed accessibility health review for roadmap step 118.15 --
/// Accessibility Health.
///
/// Objective (external canonical `sprint_118.json`): monitor keyboard blockers,
/// focus, screen reader, status text, progress semantics, chart alternatives,
/// touch targets, and contrast. The canonical signal list is exactly eight
/// items: `keyboard_blocker`, `focus_issue`, `screen_reader_issue`,
/// `status_issue`, `progress_issue`, `chart_gap`, `target_issue`, and
/// `contrast_issue`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live observation runs. The gate answers a single
/// question: does the declared review carry, for every canonical accessibility
/// signal, a reference state drawn from the committed accessibility witnesses,
/// a committed readable evidence source, a positive window bounded by the
/// charter, and a stated limitation -- while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes accessibility readings nobody
///   measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes a live assistive-technology run or a real user
///   interaction that was never taken. Refused by name, per signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed 115.7 accessibility
///   interaction baseline acceptance items, the committed 115.48 keyboard &
///   screen reader verification required evidence, the committed 114.20
///   accessibility health required evidence, the committed 116.47 brand, visual
///   & accessibility gate acceptance areas, and the committed 115.19 storage
///   usage cards acceptance items, so the review and the accessibility
///   contracts cannot drift apart.
///
/// The objective names `progress semantics`, `touch targets`, and `contrast`
/// explicitly; the committed witnesses declare those states (the storage usage
/// cards' `accessible_progress`, the baseline's `44px_touch_target` and
/// `200_percent_scale`, and the accessibility health `contrast_issue`), so the
/// review references them rather than inventing new ones. Should a future
/// canonical signal have no witness state, the gate owns a declared
/// `no_reference_state` marker and records the upstream omission as an open item
/// (`upstream_state_vocabulary_gap:<signal>`) -- an honest boundary, not a
/// violation of this step.
///
/// Live assistive-technology runs, screen reader verification, contrast
/// measurement, touch-target measurement, scale rendering, release
/// authorization, and publication remain `DEFERRED-EXTERNAL`; this review
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an accessibility health review can rest in. `blocked` is the
/// honest resting state for "this review cannot yet be trusted", and it is
/// distinct from `fail`, which means the review contradicts its own evidence.
enum Sprint118AccessibilityHealthState { pass, fail, blocked }

/// One accessibility entry: the declared reference for a single canonical
/// signal, with the boundary it was frozen under.
class Sprint118AccessibilityHealthEntry {
  const Sprint118AccessibilityHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The accessibility signal, drawn from the canonical signal vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed accessibility
  /// witness vocabulary, or the declared `no_reference_state` marker when the
  /// witness declares no state for this signal.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live assistive-technology runs or live user
  /// interactions.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118AccessibilityHealthReview {
  const Sprint118AccessibilityHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118AccessibilityHealthEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and accessibility
/// witnesses actually say. A review is only as honest as the witnesses it
/// reads.
class Sprint118AccessibilityHealthAnchor {
  const Sprint118AccessibilityHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessInteractionBaseline,
    required this.witnessKeyboardScreenReader,
    required this.witnessAccessibilityHealth,
    required this.witnessBrandVisual,
    required this.witnessStorageUsageCards,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The acceptance items the committed 115.7 accessibility interaction
  /// baseline declares.
  final List<String> witnessInteractionBaseline;

  /// The required evidence the committed 115.48 keyboard & screen reader
  /// verification declares.
  final List<String> witnessKeyboardScreenReader;

  /// The required evidence the committed 114.20 accessibility health declares.
  final List<String> witnessAccessibilityHealth;

  /// The acceptance areas the committed 116.47 brand, visual & accessibility
  /// gate declares.
  final List<String> witnessBrandVisual;

  /// The acceptance items the committed 115.19 storage usage cards declare.
  final List<String> witnessStorageUsageCards;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118AccessibilityHealthReport {
  const Sprint118AccessibilityHealthReport({
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

  final Sprint118AccessibilityHealthState state;
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
  bool get reviewVerified => state == Sprint118AccessibilityHealthState.pass;

  String get externalGates =>
      Sprint118AccessibilityHealthContract.externalGates;
}

/// The fixed vocabulary of step 118.15, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118AccessibilityHealthContract {
  const Sprint118AccessibilityHealthContract._();

  static const String canonicalStep = '118.15';
  static const String title = 'Accessibility Health';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_accessibility_health.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 115.7 accessibility interaction baseline that declares the
  /// keyboard, focus, screen-reader, chart-alternative, touch-target, and
  /// scaling acceptance items this review references.
  static const String interactionBaselineManifestPath =
      'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json';

  /// The committed 115.48 keyboard & screen reader verification that declares
  /// the focus-order, keyboard, screen-reader, status-announcement, dialog, and
  /// chart-alternative evidence this review references.
  static const String keyboardScreenReaderManifestPath =
      'docs/planning/v1.2/sprint_115_keyboard_screen_reader_verification.json';

  /// The committed 114.20 accessibility health that declares the keyboard,
  /// screen-reader, focus, scaling, contrast, motion, and non-visual evidence
  /// this review references.
  static const String accessibilityHealthManifestPath =
      'docs/planning/v1.2/sprint_114_accessibility_health.json';

  /// The committed 116.47 brand, visual & accessibility gate that declares the
  /// icon, visual, breakpoint, fallback, keyboard, screen-reader, and
  /// chart-alternative acceptance areas this review references.
  static const String brandVisualManifestPath =
      'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json';

  /// The committed 115.19 storage usage cards that declare the accessible
  /// progress and manage-action acceptance items this review references.
  static const String storageUsageCardsManifestPath =
      'docs/planning/v1.2/sprint_115_storage_usage_cards.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.15.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The eight canonical accessibility signals the objective names.
  static const List<String> accessibilitySignals = <String>[
    'keyboard_blocker',
    'focus_issue',
    'screen_reader_issue',
    'status_issue',
    'progress_issue',
    'chart_gap',
    'target_issue',
    'contrast_issue',
  ];

  /// The declared marker for a signal the committed accessibility witnesses
  /// have no state for. It is honest on the delayed path: it declares no
  /// reference state rather than inventing one.
  static const String noReferenceState = 'no_reference_state';

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
    'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
    'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
    'docs/planning/v1.2/sprint_115_keyboard_screen_reader_verification.json',
    'docs/planning/v1.2/sprint_115_storage_usage_cards.json',
    'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
    'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
    'docs/planning/v1.2/sprint_114_accessibility_health.json',
  ];

  /// The distinct union of the committed accessibility witness vocabularies, in
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
    final index = accessibilitySignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing. Every
  /// canonical signal's reference state is drawn from the committed
  /// accessibility witness vocabulary, so no `no_reference_state` marker is
  /// needed; the marker remains available for a signal the witnesses cannot yet
  /// name.
  static const Sprint118AccessibilityHealthReview
  canonicalReview = Sprint118AccessibilityHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118AccessibilityHealthEntry>[
      Sprint118AccessibilityHealthEntry(
        signal: 'keyboard_blocker',
        referenceState: 'keyboard_complete',
        source:
            'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AccessibilityHealthEntry(
        signal: 'focus_issue',
        referenceState: 'visible_focus',
        source:
            'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AccessibilityHealthEntry(
        signal: 'screen_reader_issue',
        referenceState: 'screen_reader_labels',
        source:
            'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AccessibilityHealthEntry(
        signal: 'status_issue',
        referenceState: 'status_announcements',
        source:
            'docs/planning/v1.2/sprint_115_keyboard_screen_reader_verification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AccessibilityHealthEntry(
        signal: 'progress_issue',
        referenceState: 'accessible_progress',
        source: 'docs/planning/v1.2/sprint_115_storage_usage_cards.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AccessibilityHealthEntry(
        signal: 'chart_gap',
        referenceState: 'chart_text_alternative',
        source:
            'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AccessibilityHealthEntry(
        signal: 'target_issue',
        referenceState: '44px_touch_target',
        source:
            'docs/planning/v1.2/sprint_115_accessibility_interaction_baseline.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AccessibilityHealthEntry(
        signal: 'contrast_issue',
        referenceState: 'contrast_issue',
        source: 'docs/planning/v1.2/sprint_114_accessibility_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and accessibility
/// witnesses. Never invents: an unreadable witness yields `null`, which the gate
/// reports as blocked rather than as a pass.
class Sprint118AccessibilityHealthLoader {
  const Sprint118AccessibilityHealthLoader();

  Sprint118AccessibilityHealthAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118AccessibilityHealthContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118AccessibilityHealthContract.charterManifestPath,
    );
    if (charter == null) return null;
    final interactionBaseline = _readJsonObject(
      Sprint118AccessibilityHealthContract.interactionBaselineManifestPath,
    );
    if (interactionBaseline == null) return null;
    final keyboardScreenReader = _readJsonObject(
      Sprint118AccessibilityHealthContract.keyboardScreenReaderManifestPath,
    );
    if (keyboardScreenReader == null) return null;
    final accessibilityHealth = _readJsonObject(
      Sprint118AccessibilityHealthContract.accessibilityHealthManifestPath,
    );
    if (accessibilityHealth == null) return null;
    final brandVisual = _readJsonObject(
      Sprint118AccessibilityHealthContract.brandVisualManifestPath,
    );
    if (brandVisual == null) return null;
    final storageUsageCards = _readJsonObject(
      Sprint118AccessibilityHealthContract.storageUsageCardsManifestPath,
    );
    if (storageUsageCards == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118AccessibilityHealthContract.charterWindowMinutes;

    final readable = <String>[
      for (final source
          in Sprint118AccessibilityHealthContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118AccessibilityHealthAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessInteractionBaseline: _stepList(
        interactionBaseline,
        'step_acceptance',
      ),
      witnessKeyboardScreenReader: _stepList(
        keyboardScreenReader,
        'required_evidence',
      ),
      witnessAccessibilityHealth: _stringList(
        accessibilityHealth['required_evidence'],
      ),
      witnessBrandVisual: _stringList(brandVisual['acceptance_areas']),
      witnessStorageUsageCards: _stringList(storageUsageCards['acceptance']),
      readableSources: readable,
    );
  }

  /// The canonical step list a witness declares under
  /// `sources.canonical_steps.<key>`.
  static List<String> _stepList(Map<String, dynamic> witness, String key) {
    final sources = witness['sources'];
    final sourcesMap = sources is Map<String, dynamic>
        ? sources
        : const <String, dynamic>{};
    final canonicalSteps = sourcesMap['canonical_steps'];
    final stepsMap = canonicalSteps is Map<String, dynamic>
        ? canonicalSteps
        : const <String, dynamic>{};
    return _stringList(stepsMap[key]);
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

class Sprint118AccessibilityHealthGate {
  const Sprint118AccessibilityHealthGate();

  /// Evaluate the canonical review against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118AccessibilityHealthReport evaluate() => evaluateWith(
    const Sprint118AccessibilityHealthLoader().loadAnchor(),
    Sprint118AccessibilityHealthContract.canonicalReview,
  );

  Sprint118AccessibilityHealthReport evaluateWith(
    Sprint118AccessibilityHealthAnchor? anchor,
    Sprint118AccessibilityHealthReview review,
  ) {
    if (anchor == null) {
      return Sprint118AccessibilityHealthReport(
        state: Sprint118AccessibilityHealthState.blocked,
        verdict: 'SPRINT_118_ACCESSIBILITY_HEALTH_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118AccessibilityHealthContract.requiredFields,
        ),
        blockers: const <String>[
          'committed_accessibility_health_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_accessibility_health_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes accessibility readings
    // nobody measured.
    if (anchor.baselineState !=
            Sprint118AccessibilityHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118AccessibilityHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118AccessibilityHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118AccessibilityHealthContract.requiredCharterVerdict) {
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
    // release, an observation describes a live assistive-technology run or a
    // real user interaction that was never taken.
    final delayed =
        review.releaseState ==
        Sprint118AccessibilityHealthContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'accessibility_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessInteractionBaseline.isEmpty ||
        anchor.witnessKeyboardScreenReader.isEmpty ||
        anchor.witnessAccessibilityHealth.isEmpty ||
        anchor.witnessBrandVisual.isEmpty ||
        anchor.witnessStorageUsageCards.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_accessibility_vocabulary_missing');
    }
    final vocabulary =
        Sprint118AccessibilityHealthContract.stateVocabulary(<List<String>>[
          anchor.witnessInteractionBaseline,
          anchor.witnessKeyboardScreenReader,
          anchor.witnessAccessibilityHealth,
          anchor.witnessBrandVisual,
          anchor.witnessStorageUsageCards,
        ]);

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118AccessibilityHealthContract.accessibilitySignals.contains(
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
            Sprint118AccessibilityHealthContract.noReferenceState) {
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
        in Sprint118AccessibilityHealthContract.accessibilitySignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source
        in Sprint118AccessibilityHealthContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118AccessibilityHealthReport(
        state: Sprint118AccessibilityHealthState.fail,
        verdict: 'SPRINT_118_ACCESSIBILITY_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118AccessibilityHealthReport(
        state: Sprint118AccessibilityHealthState.blocked,
        verdict: 'SPRINT_118_ACCESSIBILITY_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118AccessibilityHealthReport(
      state: Sprint118AccessibilityHealthState.pass,
      verdict: 'ACCESSIBILITY_HEALTH_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
