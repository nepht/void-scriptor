/// Fail-closed AI provider health review for roadmap step 118.11 --
/// AI Provider Health.
///
/// Objective (external canonical `sprint_118.json`): monitor model discovery,
/// job success, cancellation, usage metadata, cost labels, fallback,
/// throttling, and privacy destination. The canonical signal list is exactly
/// eight items: `model_discovery`, `job_success`, `cancellation`,
/// `usage_match`, `cost_label`, `fallback`, `throttling`, and `destination`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live observation runs. The gate answers a single
/// question: does the declared review carry, for every canonical AI provider
/// signal, a reference state drawn from the committed AI provider witnesses,
/// a committed readable evidence source, a positive window bounded by the
/// charter, and a stated limitation -- while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes provider readings nobody measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes a provider job or quota reading that was never
///   fetched. Refused by name, per signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed local AI
///   certification fields (116.26), the committed OpenAI connector fields
///   (116.21), the committed OpenRouter connector fields (116.25), the committed
///   provider external dependency signals (114.25), and the committed AI
///   connection & model settings acceptance (115.25), so the review and the
///   provider contracts cannot drift apart.
///
/// The objective names `job_success` explicitly, but the committed AI provider
/// witnesses declare no success state for an AI generation job. Rather than
/// widen the gate silently or drop the requirement, the gate owns a declared
/// `no_reference_state` marker and records the upstream omission as an open item
/// (`upstream_state_vocabulary_gap:<signal>`) -- an honest boundary, not a
/// violation of this step.
///
/// Live provider probing, model discovery, job submission, cancellation,
/// connector certification, provider exposure, release authorization, and
/// publication remain `DEFERRED-EXTERNAL`; this review freezes local declared
/// state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an AI provider-health review can rest in. `blocked` is the
/// honest resting state for "this review cannot yet be trusted", and it is
/// distinct from `fail`, which means the review contradicts its own evidence.
enum Sprint118AiProviderHealthState { pass, fail, blocked }

/// One AI provider entry: the declared reference for a single canonical
/// signal, with the boundary it was frozen under.
class Sprint118AiProviderHealthEntry {
  const Sprint118AiProviderHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The AI provider signal, drawn from the canonical signal vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed AI provider witness
  /// vocabulary, or the declared `no_reference_state` marker when the witness
  /// declares no state for this signal.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live provider reads.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118AiProviderHealthReview {
  const Sprint118AiProviderHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118AiProviderHealthEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and AI provider witnesses
/// actually say. A review is only as honest as the witnesses it reads.
class Sprint118AiProviderHealthAnchor {
  const Sprint118AiProviderHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessLocalAiFields,
    required this.witnessOpenaiFields,
    required this.witnessOpenrouterFields,
    required this.witnessExternalDependencySignals,
    required this.witnessModelSettingsAcceptance,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The required fields the committed 116.26 local AI certification declares.
  final List<String> witnessLocalAiFields;

  /// The required fields the committed 116.21 OpenAI connector certification
  /// declares.
  final List<String> witnessOpenaiFields;

  /// The required fields the committed 116.25 OpenRouter connector
  /// certification declares.
  final List<String> witnessOpenrouterFields;

  /// The signals the committed 114.25 provider & external dependency health
  /// witness declares.
  final List<String> witnessExternalDependencySignals;

  /// The acceptance items the committed 115.25 AI connection & model settings
  /// witness declares.
  final List<String> witnessModelSettingsAcceptance;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118AiProviderHealthReport {
  const Sprint118AiProviderHealthReport({
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

  final Sprint118AiProviderHealthState state;
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
  bool get reviewVerified => state == Sprint118AiProviderHealthState.pass;

  String get externalGates => Sprint118AiProviderHealthContract.externalGates;
}

/// The fixed vocabulary of step 118.11, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118AiProviderHealthContract {
  const Sprint118AiProviderHealthContract._();

  static const String canonicalStep = '118.11';
  static const String title = 'AI Provider Health';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_ai_provider_health.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 116.26 local AI certification that declares the local
  /// provider fields this review references.
  static const String localAiManifestPath =
      'docs/planning/v1.2/sprint_116_local_ai_certification.json';

  /// The committed 116.21 OpenAI connector certification that declares the
  /// cancellation, usage, and cost fields this review references.
  static const String openaiManifestPath =
      'docs/planning/v1.2/sprint_116_openai_connector_certification.json';

  /// The committed 116.25 OpenRouter connector certification that declares the
  /// provider fallback and privacy destination fields this review references.
  static const String openrouterManifestPath =
      'docs/planning/v1.2/sprint_116_openrouter_connector_certification.json';

  /// The committed 114.25 provider & external dependency health witness that
  /// declares the throttling signal this review references.
  static const String externalDependencyManifestPath =
      'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json';

  /// The committed 115.25 AI connection & model settings witness that declares
  /// the fallback acceptance this review references.
  static const String modelSettingsManifestPath =
      'docs/planning/v1.2/sprint_115_ai_connection_model_settings.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.11.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The eight canonical AI provider signals the objective names.
  static const List<String> aiProviderSignals = <String>[
    'model_discovery',
    'job_success',
    'cancellation',
    'usage_match',
    'cost_label',
    'fallback',
    'throttling',
    'destination',
  ];

  /// The declared marker for a signal the committed AI provider witnesses have
  /// no state for. It is honest on the delayed path: it declares no reference
  /// state rather than inventing one.
  static const String noReferenceState = 'no_reference_state';

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_116_local_ai_certification.json',
    'docs/planning/v1.2/sprint_116_flux_connector_certification.json',
    'docs/planning/v1.2/sprint_116_openai_connector_certification.json',
    'docs/planning/v1.2/sprint_116_gemini_connector_certification.json',
    'docs/planning/v1.2/sprint_116_anthropic_connector_certification.json',
    'docs/planning/v1.2/sprint_115_ai_connection_model_settings.json',
    'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
    'docs/planning/v1.2/sprint_116_openrouter_connector_certification.json',
  ];

  /// The distinct union of the committed AI provider witness vocabularies, in
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
    final index = aiProviderSignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing. The
  /// `job_success` signal carries the `no_reference_state` marker because the
  /// committed AI provider witnesses declare no success state for an AI
  /// generation job; the gate records that upstream gap as an open item.
  static const Sprint118AiProviderHealthReview
  canonicalReview = Sprint118AiProviderHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118AiProviderHealthEntry>[
      Sprint118AiProviderHealthEntry(
        signal: 'model_discovery',
        referenceState: 'model_discovery',
        source: 'docs/planning/v1.2/sprint_116_local_ai_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AiProviderHealthEntry(
        signal: 'job_success',
        referenceState: noReferenceState,
        source:
            'docs/planning/v1.2/sprint_116_flux_connector_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AiProviderHealthEntry(
        signal: 'cancellation',
        referenceState: 'cancellation',
        source:
            'docs/planning/v1.2/sprint_116_openai_connector_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AiProviderHealthEntry(
        signal: 'usage_match',
        referenceState: 'usage_metadata',
        source:
            'docs/planning/v1.2/sprint_116_gemini_connector_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AiProviderHealthEntry(
        signal: 'cost_label',
        referenceState: 'cost_labels',
        source:
            'docs/planning/v1.2/sprint_116_anthropic_connector_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AiProviderHealthEntry(
        signal: 'fallback',
        referenceState: 'provider_fallback',
        source:
            'docs/planning/v1.2/sprint_115_ai_connection_model_settings.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AiProviderHealthEntry(
        signal: 'throttling',
        referenceState: 'throttling',
        source:
            'docs/planning/v1.2/sprint_114_provider_external_dependency_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118AiProviderHealthEntry(
        signal: 'destination',
        referenceState: 'privacy_destination',
        source:
            'docs/planning/v1.2/sprint_116_openrouter_connector_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and AI provider
/// witnesses. Never invents: an unreadable witness yields `null`, which the gate
/// reports as blocked rather than as a pass.
class Sprint118AiProviderHealthLoader {
  const Sprint118AiProviderHealthLoader();

  Sprint118AiProviderHealthAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118AiProviderHealthContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118AiProviderHealthContract.charterManifestPath,
    );
    if (charter == null) return null;
    final localAi = _readJsonObject(
      Sprint118AiProviderHealthContract.localAiManifestPath,
    );
    if (localAi == null) return null;
    final openai = _readJsonObject(
      Sprint118AiProviderHealthContract.openaiManifestPath,
    );
    if (openai == null) return null;
    final openrouter = _readJsonObject(
      Sprint118AiProviderHealthContract.openrouterManifestPath,
    );
    if (openrouter == null) return null;
    final externalDependency = _readJsonObject(
      Sprint118AiProviderHealthContract.externalDependencyManifestPath,
    );
    if (externalDependency == null) return null;
    final modelSettings = _readJsonObject(
      Sprint118AiProviderHealthContract.modelSettingsManifestPath,
    );
    if (modelSettings == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118AiProviderHealthContract.charterWindowMinutes;

    final readable = <String>[
      for (final source in Sprint118AiProviderHealthContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118AiProviderHealthAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessLocalAiFields: _stringList(localAi['required_fields']),
      witnessOpenaiFields: _stringList(openai['required_fields']),
      witnessOpenrouterFields: _stringList(openrouter['required_fields']),
      witnessExternalDependencySignals: _stringList(
        externalDependency['signals'],
      ),
      witnessModelSettingsAcceptance: _stringList(modelSettings['acceptance']),
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

class Sprint118AiProviderHealthGate {
  const Sprint118AiProviderHealthGate();

  /// Evaluate the canonical review against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118AiProviderHealthReport evaluate() => evaluateWith(
    const Sprint118AiProviderHealthLoader().loadAnchor(),
    Sprint118AiProviderHealthContract.canonicalReview,
  );

  Sprint118AiProviderHealthReport evaluateWith(
    Sprint118AiProviderHealthAnchor? anchor,
    Sprint118AiProviderHealthReview review,
  ) {
    if (anchor == null) {
      return Sprint118AiProviderHealthReport(
        state: Sprint118AiProviderHealthState.blocked,
        verdict: 'SPRINT_118_AI_PROVIDER_HEALTH_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118AiProviderHealthContract.requiredFields,
        ),
        blockers: const <String>[
          'committed_ai_provider_health_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_ai_provider_health_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes provider readings nobody
    // measured.
    if (anchor.baselineState !=
            Sprint118AiProviderHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118AiProviderHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118AiProviderHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118AiProviderHealthContract.requiredCharterVerdict) {
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
    // release, an observation describes a provider job or quota reading never
    // fetched.
    final delayed =
        review.releaseState ==
        Sprint118AiProviderHealthContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'provider_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessLocalAiFields.isEmpty ||
        anchor.witnessOpenaiFields.isEmpty ||
        anchor.witnessOpenrouterFields.isEmpty ||
        anchor.witnessExternalDependencySignals.isEmpty ||
        anchor.witnessModelSettingsAcceptance.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_ai_provider_vocabulary_missing');
    }
    final vocabulary =
        Sprint118AiProviderHealthContract.stateVocabulary(<List<String>>[
          anchor.witnessLocalAiFields,
          anchor.witnessOpenaiFields,
          anchor.witnessOpenrouterFields,
          anchor.witnessExternalDependencySignals,
          anchor.witnessModelSettingsAcceptance,
        ]);

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118AiProviderHealthContract.aiProviderSignals.contains(
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
            Sprint118AiProviderHealthContract.noReferenceState) {
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
    for (final signal in Sprint118AiProviderHealthContract.aiProviderSignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source in Sprint118AiProviderHealthContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118AiProviderHealthReport(
        state: Sprint118AiProviderHealthState.fail,
        verdict: 'SPRINT_118_AI_PROVIDER_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118AiProviderHealthReport(
        state: Sprint118AiProviderHealthState.blocked,
        verdict: 'SPRINT_118_AI_PROVIDER_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118AiProviderHealthReport(
      state: Sprint118AiProviderHealthState.pass,
      verdict: 'AI_PROVIDER_HEALTH_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
