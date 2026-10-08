/// Fail-closed privacy-safe observation verification for roadmap step 118.5 --
/// Privacy-Safe Observation Verification.
///
/// Objective (external canonical `sprint_118.json`): ensure that observation
/// never collects manuscripts, lore, characters, media, prompts, secrets, or raw
/// payment data. The canonical acceptance list is exactly seven items:
/// `creative_content_excluded`, `secrets_excluded`, `raw_payment_excluded`,
/// `consent`, `minimization`, `retention`, and `disable_control`.
///
/// This is the verification that the observation plan frozen by the delayed
/// corrective path (Sprint 118 on `GA_DELAYED`) is privacy-safe *before* any
/// live observation runs. The gate therefore answers a single question: does the
/// declared observation collect only aggregate, non-creative, non-secret,
/// non-payment fields, under explicit consent, minimization, bounded retention,
/// and an available disable control?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A privacy
///   verification built on a baseline that did not freeze describes an
///   observation nobody recorded.
/// * The observation's release state must agree with the baseline anchor. On the
///   delayed path no observation may claim to have executed telemetry.
/// * The committed consent gate must remain `opt-in default OFF`, and the
///   observation must never enable default collection.
/// * Every signal's collected fields are classified against the full exclusion
///   vocabulary (creative content, secrets, raw payment data, media). A signal
///   that admits any excluded field is refused by name, per signal and field.
/// * Every signal must require explicit consent, be minimized, expose a disable
///   control, and carry a positive retention no larger than the contract
///   maximum.
/// * Every canonical signal must be present exactly once, must collect at least
///   one field, and every committed privacy-evidence source must be readable.
///
/// The objective names media and raw payment data explicitly, but the committed
/// 117.7 witness omits both from its `excluded_categories`. Rather than widen the
/// gate silently or drop the requirement, the gate owns the full vocabulary and
/// records the upstream omission as an open item -- an honest boundary, not a
/// violation of this step.
///
/// Live observation execution, external telemetry, connector certification,
/// provider exposure, release authorization, and publication remain
/// `DEFERRED-EXTERNAL`; this verification freezes local declared state and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a privacy-observation evaluation can rest in. `blocked` is
/// the honest resting state for "this verification cannot yet be trusted", and
/// it is distinct from `fail`, which means the observation contradicts its own
/// evidence.
enum Sprint118PrivacyState { pass, fail, blocked }

/// One observation signal: the declared collection surface for a single health
/// signal, with the privacy controls it carries.
class Sprint118ObservationSignal {
  const Sprint118ObservationSignal({
    required this.signal,
    required this.collectedFields,
    required this.requiresExplicitConsent,
    required this.minimized,
    required this.retentionDays,
    required this.disableControl,
  });

  /// The signal identifier, drawn from the canonical signal vocabulary.
  final String signal;

  /// The fields this signal collects. Every one is classified against the
  /// exclusion vocabulary; any excluded field fails the gate.
  final List<String> collectedFields;

  /// Whether this signal requires explicit consent. Must stay `true`.
  final bool requiresExplicitConsent;

  /// Whether this signal is minimized to aggregate/necessary fields only.
  final bool minimized;

  /// How long the collected data is retained, in days. Must be positive and no
  /// larger than [Sprint118PrivacyObservationContract.maxRetentionDays].
  final int retentionDays;

  /// Whether a disable control exists for this signal. Must stay `true`.
  final bool disableControl;
}

/// The declared observation plan. `signals` is the collection surface for the
/// delayed corrective path; on that path no signal may observe anything live.
class Sprint118PrivacyObservation {
  const Sprint118PrivacyObservation({
    required this.releaseState,
    required this.defaultCollection,
    required this.signals,
  });

  final String releaseState;
  final bool defaultCollection;
  final List<Sprint118ObservationSignal> signals;

  List<String> get signalIds => <String>[
    for (final signal in signals) signal.signal,
  ];

  int get collectedFieldCount => signals.fold<int>(
    0,
    (sum, signal) => sum + signal.collectedFields.length,
  );
}

/// What the committed 118.4 baseline and 117.7 privacy-safe monitoring witness
/// actually say. A verification is only as honest as the witnesses it reads.
class Sprint118PrivacyObservationAnchor {
  const Sprint118PrivacyObservationAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.consentGate,
    required this.defaultCollection,
    required this.telemetryExecuted,
    required this.excludedCategories,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;

  /// The committed consent gate string, e.g. `opt-in default OFF`.
  final String consentGate;

  /// Whether the committed witness enables default collection. Must stay
  /// `false`.
  final bool defaultCollection;

  /// Whether the committed witness claims telemetry executed. On the delayed
  /// path this must stay `false`.
  final bool telemetryExecuted;

  /// The exclusion vocabulary the committed witness declares.
  final List<String> excludedCategories;

  /// The committed privacy-evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the observation is privacy-safe; `blocked`
/// means it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118PrivacyObservationReport {
  const Sprint118PrivacyObservationReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredSignals = const <String>[],
    this.collectedFieldCount = 0,
  });

  final Sprint118PrivacyState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredSignals;
  final int collectedFieldCount;

  /// Whether the observation may be treated as privacy-safe. Only a genuine
  /// `pass` allows it.
  bool get observationVerified => state == Sprint118PrivacyState.pass;

  String get externalGates => Sprint118PrivacyObservationContract.externalGates;
}

/// The fixed vocabulary of step 118.5, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118PrivacyObservationContract {
  const Sprint118PrivacyObservationContract._();

  static const String canonicalStep = '118.5';
  static const String title = 'Privacy-Safe Observation Verification';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_privacy_safe_observation.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this verification is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 117.7 privacy-safe monitoring witness that declares the
  /// consent gate, default-collection state, and exclusion vocabulary.
  static const String privacySafeMonitoringManifestPath =
      'docs/planning/v1.3/sprint_117_privacy_safe_monitoring.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';
  static const String delayedReleaseState = 'GA_DELAYED';
  static const String releasedReleaseState = 'GA_RELEASED';

  /// The committed consent gate that must remain in force.
  static const String requiredConsentGate = 'opt-in default OFF';

  /// The seven canonical acceptance items from `sprint_118.json` step 118.5.
  static const List<String> acceptanceFields = <String>[
    'creative_content_excluded',
    'secrets_excluded',
    'raw_payment_excluded',
    'consent',
    'minimization',
    'retention',
    'disable_control',
  ];

  /// Creative-content terms that must never be admitted by a signal.
  static const List<String> creativeTerms = <String>[
    'manuscript',
    'novel',
    'chapter',
    'scene',
    'character',
    'lore',
    'worldbuilding',
    'prompt',
    'draft',
    'outline',
    'creative',
  ];

  /// Secret terms that must never be admitted by a signal.
  static const List<String> secretTerms = <String>[
    'credential',
    'password',
    'secret',
    'token',
    'api_key',
    'private_key',
  ];

  /// Raw payment terms that must never be admitted by a signal.
  static const List<String> rawPaymentTerms = <String>[
    'payment',
    'card_number',
    'card',
    'cvv',
    'cvc',
    'iban',
    'account_number',
    'raw_payment',
  ];

  /// Media terms that must never be admitted by a signal.
  static const List<String> mediaTerms = <String>[
    'media',
    'screenshot',
    'recording',
    'video',
    'image',
    'audio',
    'photo',
  ];

  /// The full exclusion vocabulary this step owns: the union of the four
  /// families. The objective names media and raw payment explicitly even though
  /// the committed 117.7 witness omits them.
  static List<String> get excludedVocabulary => <String>[
    ...creativeTerms,
    ...secretTerms,
    ...rawPaymentTerms,
    ...mediaTerms,
  ];

  /// The maximum retention, in days, a signal may declare. The committed 117.7
  /// witness pins 30 days for every signal.
  static const int maxRetentionDays = 30;

  /// The committed privacy-evidence sources the canonical observation is
  /// anchored to.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.3/sprint_118_post_release_health_baseline.json',
    'docs/planning/v1.3/sprint_117_privacy_safe_monitoring.json',
    'docs/planning/v1.2/sprint_114_privacy_safe_monitoring.json',
    'docs/planning/v1.2/sprint_113_privacy_safe_evidence_plan.json',
    'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
  ];

  /// The canonical observation, declared here as the single source of truth. The
  /// gate evaluates exactly this object, and the emitter writes exactly this
  /// object, so the record cannot be made to agree with itself. With the release
  /// delayed, every signal declares a reference and observes nothing live.
  static const Sprint118PrivacyObservation canonicalObservation =
      Sprint118PrivacyObservation(
        releaseState: delayedReleaseState,
        defaultCollection: false,
        signals: <Sprint118ObservationSignal>[
          Sprint118ObservationSignal(
            signal: 'connection_outcome',
            collectedFields: <String>[
              'connection_state',
              'health_state',
              'transition',
              'http_status_class',
              'retry_after_seconds',
            ],
            requiresExplicitConsent: true,
            minimized: true,
            retentionDays: 30,
            disableControl: true,
          ),
          Sprint118ObservationSignal(
            signal: 'quota_refresh',
            collectedFields: <String>[
              'provider_id',
              'unit_kind',
              'raw_units',
              'observed_at_epoch_ms',
              'freshness_ttl_seconds',
            ],
            requiresExplicitConsent: true,
            minimized: true,
            retentionDays: 30,
            disableControl: true,
          ),
          Sprint118ObservationSignal(
            signal: 'sync_outcome',
            collectedFields: <String>[
              'queue_depth',
              'retry_resume',
              'conflict_resolution',
              'restore_result',
              'workspace_boundary',
            ],
            requiresExplicitConsent: true,
            minimized: true,
            retentionDays: 30,
            disableControl: true,
          ),
          Sprint118ObservationSignal(
            signal: 'provider_error',
            collectedFields: <String>[
              'provider_id',
              'error_state',
              'http_status',
              'retryable',
              'retry_after_seconds',
            ],
            requiresExplicitConsent: true,
            minimized: true,
            retentionDays: 30,
            disableControl: true,
          ),
          Sprint118ObservationSignal(
            signal: 'usage_metadata',
            collectedFields: <String>[
              'provider_id',
              'usage_units',
              'provider_cost',
              'currency',
              'is_estimate',
              'measured_at',
            ],
            requiresExplicitConsent: true,
            minimized: true,
            retentionDays: 30,
            disableControl: true,
          ),
          Sprint118ObservationSignal(
            signal: 'billing_state',
            collectedFields: <String>[
              'event_type',
              'signature_status',
              'sequence',
              'retry_count',
              'entitlement_status',
            ],
            requiresExplicitConsent: true,
            minimized: true,
            retentionDays: 30,
            disableControl: true,
          ),
          Sprint118ObservationSignal(
            signal: 'workflow_completion',
            collectedFields: <String>[
              'workflow_outcome',
              'feature_area',
              'duration_bucket',
              'error_class',
            ],
            requiresExplicitConsent: true,
            minimized: true,
            retentionDays: 30,
            disableControl: true,
          ),
        ],
      );

  /// Classify a field name against the exclusion vocabulary. Returns one of
  /// `creative`, `secret`, `payment`, or `media`, or `null` when the field is
  /// not an excluded category. Creative content is checked first, then secrets,
  /// then raw payment data, then media, so a field that matches several
  /// families is reported under the most protective one.
  static String? fieldCategory(String field) {
    final name = field.toLowerCase();
    bool has(List<String> terms) => terms.any((term) => name.contains(term));
    if (has(creativeTerms)) return 'creative';
    if (has(secretTerms)) return 'secret';
    if (has(rawPaymentTerms)) return 'payment';
    if (has(mediaTerms)) return 'media';
    return null;
  }
}

/// Reads the committed 118.4 baseline and 117.7 privacy-safe monitoring witness.
/// Never invents: an unreadable witness yields `null`, which the gate reports as
/// blocked rather than as a pass.
class Sprint118PrivacyObservationLoader {
  const Sprint118PrivacyObservationLoader();

  Sprint118PrivacyObservationAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118PrivacyObservationContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final monitoring = _readJsonObject(
      Sprint118PrivacyObservationContract.privacySafeMonitoringManifestPath,
    );
    if (monitoring == null) return null;

    final excluded = monitoring['excluded_categories'];
    final excludedCategories = excluded is List
        ? <String>[
            for (final item in excluded)
              if (item is String) item,
          ]
        : const <String>[];

    final readable = <String>[
      for (final source in Sprint118PrivacyObservationContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118PrivacyObservationAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      consentGate: _text(monitoring['consent_gate']),
      defaultCollection: monitoring['default_collection'] == true,
      telemetryExecuted: monitoring['telemetry_executed'] == true,
      excludedCategories: excludedCategories,
      readableSources: readable,
    );
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
}

class Sprint118PrivacyObservationGate {
  const Sprint118PrivacyObservationGate();

  /// Evaluate the canonical observation against committed evidence. This is the
  /// entry point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118PrivacyObservationReport evaluate() => evaluateWith(
    const Sprint118PrivacyObservationLoader().loadAnchor(),
    Sprint118PrivacyObservationContract.canonicalObservation,
  );

  Sprint118PrivacyObservationReport evaluateWith(
    Sprint118PrivacyObservationAnchor? anchor,
    Sprint118PrivacyObservation observation,
  ) {
    if (anchor == null) {
      return Sprint118PrivacyObservationReport(
        state: Sprint118PrivacyState.blocked,
        verdict: 'SPRINT_118_PRIVACY_EVIDENCE_UNREADABLE',
        releaseState: observation.releaseState,
        missingFields: List<String>.from(
          Sprint118PrivacyObservationContract.acceptanceFields,
        ),
        blockers: const <String>['committed_privacy_evidence_unreadable'],
        openItems: const <String>['committed_privacy_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A privacy
    // verification written against an unfrozen baseline describes an
    // observation nobody recorded.
    if (anchor.baselineState !=
            Sprint118PrivacyObservationContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118PrivacyObservationContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The release state must agree with the baseline anchor.
    if (anchor.releaseState != observation.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'observation=${observation.releaseState}',
      );
    }

    // (3) Default collection must never be enabled.
    if (observation.defaultCollection) {
      violations.add('default_collection_enabled');
    }

    // (4) The committed consent gate must remain opt-in default OFF.
    if (anchor.consentGate !=
        Sprint118PrivacyObservationContract.requiredConsentGate) {
      violations.add('consent_gate_not_opt_in_default_off');
    }

    // (5) On the delayed path no telemetry may be claimed executed.
    final delayed =
        observation.releaseState ==
        Sprint118PrivacyObservationContract.delayedReleaseState;
    if (delayed && anchor.telemetryExecuted) {
      violations.add('telemetry_claimed_executed_without_release');
    }

    // (6) Every canonical signal must be present exactly once, and each signal
    // must carry every privacy control.
    final declared = <String, int>{};
    for (final signal in observation.signals) {
      declared[signal.signal] = (declared[signal.signal] ?? 0) + 1;
    }
    for (final signal in observation.signals) {
      final id = signal.signal;
      if (signal.collectedFields.isEmpty) {
        violations.add('signal_no_fields:$id');
      }
      for (final field in signal.collectedFields) {
        final category = Sprint118PrivacyObservationContract.fieldCategory(
          field,
        );
        switch (category) {
          case 'creative':
            violations.add('creative_content_collected:$id:$field');
          case 'secret':
            violations.add('secret_collected:$id:$field');
          case 'payment':
            violations.add('raw_payment_collected:$id:$field');
          case 'media':
            violations.add('media_collected:$id:$field');
        }
      }
      if (!signal.requiresExplicitConsent) {
        violations.add('signal_without_consent:$id');
      }
      if (!signal.minimized) {
        violations.add('signal_not_minimized:$id');
      }
      if (!signal.disableControl) {
        violations.add('signal_without_disable_control:$id');
      }
      if (signal.retentionDays <= 0) {
        violations.add('retention_nonpositive:$id:${signal.retentionDays}');
      } else if (signal.retentionDays >
          Sprint118PrivacyObservationContract.maxRetentionDays) {
        violations.add(
          'retention_exceeds_max:$id:${signal.retentionDays}:'
          '${Sprint118PrivacyObservationContract.maxRetentionDays}',
        );
      }
    }
    for (final id in declared.keys) {
      if (declared[id]! > 1) {
        violations.add('duplicate_signal:$id');
      }
    }
    final canonicalIds =
        Sprint118PrivacyObservationContract.canonicalObservation.signalIds;
    for (final id in canonicalIds) {
      if (!declared.containsKey(id)) {
        violations.add('signal_missing:$id');
      }
    }

    // (7) Every committed privacy-evidence source must be readable.
    for (final source in Sprint118PrivacyObservationContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    // The committed 117.7 witness omits media and raw payment from its
    // exclusion vocabulary even though the 118.5 objective names both. Record
    // the gap as an open item -- honest, and not a violation of this step.
    for (final term in <String>['media', 'payment']) {
      if (!anchor.excludedCategories.contains(term)) {
        openItems.add('upstream_exclusion_vocabulary_gap:$term');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = observation.signalIds;

    if (violations.isNotEmpty) {
      return Sprint118PrivacyObservationReport(
        state: Sprint118PrivacyState.fail,
        verdict: 'SPRINT_118_PRIVACY_OBSERVATION_VIOLATION',
        releaseState: observation.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        collectedFieldCount: observation.collectedFieldCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118PrivacyObservationReport(
        state: Sprint118PrivacyState.blocked,
        verdict: 'SPRINT_118_PRIVACY_BLOCKED_UPSTREAM',
        releaseState: observation.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        collectedFieldCount: observation.collectedFieldCount,
      );
    }
    return Sprint118PrivacyObservationReport(
      state: Sprint118PrivacyState.pass,
      verdict: 'PRIVACY_SAFE_OBSERVATION_VERIFIED_LOCAL',
      releaseState: observation.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      collectedFieldCount: observation.collectedFieldCount,
    );
  }
}
