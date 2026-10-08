/// Fail-closed OAuth & reauthentication health review for roadmap step 118.8 --
/// OAuth & Reauthentication Health.
///
/// Objective (external canonical `sprint_118.json`): monitor callback errors,
/// state failures, token rotation, reauth completion, scope changes, and
/// provider revoke. The canonical signal list is exactly six items:
/// `callback_error`, `state_failure`, `rotation_failure`, `reauth_completion`,
/// `scope_change`, and `provider_revoke`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live observation runs. The gate answers a single
/// question: does the declared review carry, for every canonical OAuth signal,
/// a reference state drawn from the committed OAuth/reauthentication witnesses,
/// a committed readable evidence source, a positive window bounded by the
/// charter, and a stated limitation -- while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes authentications nobody measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes an OAuth exchange that was never exercised. Refused
///   by name, per signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed OAuth flow witness
///   (115.11 protocol surfaces) and the committed reauthentication witness
///   (115.43 acceptance), so the review and the OAuth/reauthentication contracts
///   cannot drift apart.
///
/// Live OAuth exchange, provider probing, credential access, connector
/// certification, provider exposure, release authorization, and publication
/// remain `DEFERRED-EXTERNAL`; this review freezes local declared state and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states an OAuth-health review can rest in. `blocked` is the honest
/// resting state for "this review cannot yet be trusted", and it is distinct
/// from `fail`, which means the review contradicts its own evidence.
enum Sprint118OAuthReauthHealthState { pass, fail, blocked }

/// One OAuth/reauthentication entry: the declared reference for a single
/// canonical signal, with the boundary it was frozen under.
class Sprint118OAuthReauthHealthEntry {
  const Sprint118OAuthReauthHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The OAuth/reauthentication signal, drawn from the canonical vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed OAuth flow and
  /// reauthentication witness vocabulary.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live authentication.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118OAuthReauthHealthReview {
  const Sprint118OAuthReauthHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118OAuthReauthHealthEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and OAuth/reauthentication
/// witnesses actually say. A review is only as honest as the witnesses it reads.
class Sprint118OAuthReauthHealthAnchor {
  const Sprint118OAuthReauthHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessOAuthSurfaces,
    required this.witnessReauthAcceptance,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The OAuth protocol surfaces the committed 115.11 flow witness declares.
  final List<String> witnessOAuthSurfaces;

  /// The acceptance items the committed 115.43 reauthentication witness
  /// declares.
  final List<String> witnessReauthAcceptance;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118OAuthReauthHealthReport {
  const Sprint118OAuthReauthHealthReport({
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

  final Sprint118OAuthReauthHealthState state;
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
  bool get reviewVerified => state == Sprint118OAuthReauthHealthState.pass;

  String get externalGates => Sprint118OAuthReauthHealthContract.externalGates;
}

/// The fixed vocabulary of step 118.8, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118OAuthReauthHealthContract {
  const Sprint118OAuthReauthHealthContract._();

  static const String canonicalStep = '118.8';
  static const String title = 'OAuth & Reauthentication Health';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_oauth_reauth_health.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 115.11 OAuth flow witness that declares the protocol
  /// surfaces this review references.
  static const String oauthFlowManifestPath =
      'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json';

  /// The committed 115.43 reauthentication witness that declares the acceptance
  /// items this review references.
  static const String reauthManifestPath =
      'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.8.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The six canonical OAuth/reauthentication signals the objective names.
  static const List<String> oauthHealthSignals = <String>[
    'callback_error',
    'state_failure',
    'rotation_failure',
    'reauth_completion',
    'scope_change',
    'provider_revoke',
  ];

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json',
    'docs/planning/v1.2/sprint_116_provider_error_state_certification.json',
    'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
    'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json',
    'docs/planning/v1.2/sprint_115_connected_accounts_management.json',
    'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
  ];

  /// The distinct union of the committed OAuth flow witness protocol surfaces
  /// and the committed reauthentication witness acceptance items, in witness
  /// order: OAuth surfaces, then reauth acceptance.
  static List<String> stateVocabulary(
    List<String> oauthSurfaces,
    List<String> reauthAcceptance,
  ) {
    final seen = <String>{};
    final result = <String>[];
    for (final state in <String>[...oauthSurfaces, ...reauthAcceptance]) {
      if (seen.add(state)) result.add(state);
    }
    return result;
  }

  /// The evidence source registered for a canonical signal.
  static String sourceFor(String signal) {
    final index = oauthHealthSignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing. Each
  /// reference state is drawn from the committed OAuth flow witness (115.11) or
  /// the committed reauthentication witness (115.43).
  static const Sprint118OAuthReauthHealthReview
  canonicalReview = Sprint118OAuthReauthHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118OAuthReauthHealthEntry>[
      Sprint118OAuthReauthHealthEntry(
        signal: 'callback_error',
        referenceState: 'callback',
        source: 'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json',
        window: 60,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118OAuthReauthHealthEntry(
        signal: 'state_failure',
        referenceState: 'state',
        source:
            'docs/planning/v1.2/sprint_116_provider_error_state_certification.json',
        window: 60,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118OAuthReauthHealthEntry(
        signal: 'rotation_failure',
        referenceState: 'token_rotation',
        source: 'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
        window: 60,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118OAuthReauthHealthEntry(
        signal: 'reauth_completion',
        referenceState: 'reauth',
        source:
            'docs/planning/v1.2/sprint_115_token_expiry_reauthentication_ux.json',
        window: 60,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118OAuthReauthHealthEntry(
        signal: 'scope_change',
        referenceState: 'scoped_consent',
        source:
            'docs/planning/v1.2/sprint_115_connected_accounts_management.json',
        window: 60,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118OAuthReauthHealthEntry(
        signal: 'provider_revoke',
        referenceState: 'revoke',
        source:
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and OAuth/reauthentication
/// witnesses. Never invents: an unreadable witness yields `null`, which the gate
/// reports as blocked rather than as a pass.
class Sprint118OAuthReauthHealthLoader {
  const Sprint118OAuthReauthHealthLoader();

  Sprint118OAuthReauthHealthAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118OAuthReauthHealthContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118OAuthReauthHealthContract.charterManifestPath,
    );
    if (charter == null) return null;
    final oauthFlow = _readJsonObject(
      Sprint118OAuthReauthHealthContract.oauthFlowManifestPath,
    );
    if (oauthFlow == null) return null;
    final reauth = _readJsonObject(
      Sprint118OAuthReauthHealthContract.reauthManifestPath,
    );
    if (reauth == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118OAuthReauthHealthContract.charterWindowMinutes;

    final protocol = oauthFlow['protocol'];
    final protocolMap = protocol is Map<String, dynamic>
        ? protocol
        : const <String, dynamic>{};
    final oauthSurfaces = protocolMap.keys.toList();

    final readable = <String>[
      for (final source in Sprint118OAuthReauthHealthContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118OAuthReauthHealthAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessOAuthSurfaces: oauthSurfaces,
      witnessReauthAcceptance: _stringList(reauth['acceptance']),
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

class Sprint118OAuthReauthHealthGate {
  const Sprint118OAuthReauthHealthGate();

  /// Evaluate the canonical review against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118OAuthReauthHealthReport evaluate() => evaluateWith(
    const Sprint118OAuthReauthHealthLoader().loadAnchor(),
    Sprint118OAuthReauthHealthContract.canonicalReview,
  );

  Sprint118OAuthReauthHealthReport evaluateWith(
    Sprint118OAuthReauthHealthAnchor? anchor,
    Sprint118OAuthReauthHealthReview review,
  ) {
    if (anchor == null) {
      return Sprint118OAuthReauthHealthReport(
        state: Sprint118OAuthReauthHealthState.blocked,
        verdict: 'SPRINT_118_OAUTH_REAUTH_HEALTH_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118OAuthReauthHealthContract.requiredFields,
        ),
        blockers: const <String>['committed_oauth_reauth_evidence_unreadable'],
        openItems: const <String>['committed_oauth_reauth_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes authentications nobody
    // measured.
    if (anchor.baselineState !=
            Sprint118OAuthReauthHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118OAuthReauthHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118OAuthReauthHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118OAuthReauthHealthContract.requiredCharterVerdict) {
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
    // release, an observation describes an OAuth exchange never exercised.
    final delayed =
        review.releaseState ==
        Sprint118OAuthReauthHealthContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'oauth_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessOAuthSurfaces.isEmpty ||
        anchor.witnessReauthAcceptance.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_oauth_vocabulary_missing');
    }
    final vocabulary = Sprint118OAuthReauthHealthContract.stateVocabulary(
      anchor.witnessOAuthSurfaces,
      anchor.witnessReauthAcceptance,
    );

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118OAuthReauthHealthContract.oauthHealthSignals.contains(
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
      // than failed.
      if (entry.referenceState.trim().isNotEmpty && !witnessIncomplete) {
        if (!vocabulary.contains(entry.referenceState)) {
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
        in Sprint118OAuthReauthHealthContract.oauthHealthSignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source in Sprint118OAuthReauthHealthContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118OAuthReauthHealthReport(
        state: Sprint118OAuthReauthHealthState.fail,
        verdict: 'SPRINT_118_OAUTH_REAUTH_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118OAuthReauthHealthReport(
        state: Sprint118OAuthReauthHealthState.blocked,
        verdict: 'SPRINT_118_OAUTH_REAUTH_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118OAuthReauthHealthReport(
      state: Sprint118OAuthReauthHealthState.pass,
      verdict: 'OAUTH_REAUTH_HEALTH_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
