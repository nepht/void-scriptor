/// Fail-closed security health review for roadmap step 118.18 --
/// Security Health Review.
///
/// Objective (external canonical `sprint_118.json`): monitor OAuth, vault,
/// sessions, permissions, redirects, webhooks, dependencies, log redaction, and
/// suspicious actions. The canonical signal list is exactly eight items:
/// `oauth_alert`, `vault_health`, `session_alert`, `permission_denial`,
/// `redirect_alert`, `webhook_alert`, `dependency_alert`, and
/// `redaction_failure`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live security observation runs. The gate answers a
/// single question: does the declared review carry, for every canonical security
/// signal, a reference state drawn from the committed security witnesses, a
/// committed readable evidence source, a positive window bounded by the
/// charter, and a stated limitation -- while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes security readings nobody measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes a live OAuth alert, a real vault read, a real session
///   revocation, or a real dependency advisory that was never observed. Refused
///   by name, per signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed 116.45 security
///   certification gate, the committed 115.12 secure token & secret vault, the
///   committed 115.33 session & device management, the committed 115.11 OAuth &
///   linked identity flow, and the committed 116.6 credential & secret test
///   safety, so the review and the security contracts cannot drift apart.
///
/// All eight canonical signals have a witness state, so no `no_reference_state`
/// marker is needed and no upstream gap is recorded: `oauth_alert`,
/// `permission_denial`, `redirect_alert`, `webhook_alert`, and
/// `dependency_alert` draw from the 116.45 security certification gate
/// (`oauth_tests`, `permission_tests`, `redirect_tests`, `webhook_tests`,
/// `dependency_scan`), `vault_health` from the 115.12 secure token & secret
/// vault (`os_secure_store`), `session_alert` from the 115.33 session & device
/// management (`security_alert`), and `redaction_failure` from the 116.6
/// credential & secret test safety (`redaction`). The marker remains available
/// for any signal the witnesses cannot yet name.
///
/// Live OAuth handshakes, real vault and key custody, live session revocation,
/// runtime permission enforcement, production redirect allow-lists, real
/// webhook signature verification, live dependency advisory scans, release
/// authorization, and publication remain `DEFERRED-EXTERNAL`; this review
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a security health review can rest in. `blocked` is the
/// honest resting state for "this review cannot yet be trusted", and it is
/// distinct from `fail`, which means the review contradicts its own evidence.
enum Sprint118SecurityHealthState { pass, fail, blocked }

/// One security entry: the declared reference for a single canonical signal,
/// with the boundary it was frozen under.
class Sprint118SecurityHealthEntry {
  const Sprint118SecurityHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The security signal, drawn from the canonical signal vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed security witness
  /// vocabulary, or the declared `no_reference_state` marker when the witness
  /// declares no state for this signal.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live OAuth alerts, vault reads, session
  /// revocations, or dependency advisories.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118SecurityHealthReview {
  const Sprint118SecurityHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118SecurityHealthEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and security witnesses
/// actually say. A review is only as honest as the witnesses it reads.
class Sprint118SecurityHealthAnchor {
  const Sprint118SecurityHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessSecurityCertification,
    required this.witnessTokenVault,
    required this.witnessSessionDevice,
    required this.witnessOAuthIdentity,
    required this.witnessCredentialSafety,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The acceptance areas the committed 116.45 security certification gate
  /// declares.
  final List<String> witnessSecurityCertification;

  /// The acceptance items the committed 115.12 secure token & secret vault
  /// declares.
  final List<String> witnessTokenVault;

  /// The acceptance items the committed 115.33 session & device management
  /// declares.
  final List<String> witnessSessionDevice;

  /// The acceptance items the committed 115.11 OAuth & linked identity flow
  /// declares.
  final List<String> witnessOAuthIdentity;

  /// The required controls the committed 116.6 credential & secret test safety
  /// declares.
  final List<String> witnessCredentialSafety;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118SecurityHealthReport {
  const Sprint118SecurityHealthReport({
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

  final Sprint118SecurityHealthState state;
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
  bool get reviewVerified => state == Sprint118SecurityHealthState.pass;

  String get externalGates => Sprint118SecurityHealthContract.externalGates;
}

/// The fixed vocabulary of step 118.18, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118SecurityHealthContract {
  const Sprint118SecurityHealthContract._();

  static const String canonicalStep = '118.18';
  static const String title = 'Security Health Review';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_security_health_review.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 116.45 security certification gate that declares the OAuth,
  /// vault, redirect, session, permission, webhook, dependency, and audit
  /// acceptance areas this review references.
  static const String securityCertificationManifestPath =
      'docs/planning/v1.2/sprint_116_security_certification_gate.json';

  /// The committed 115.12 secure token & secret vault that declares the secure
  /// store and audit-redaction acceptance items this review references.
  static const String tokenVaultManifestPath =
      'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json';

  /// The committed 115.33 session & device management that declares the session
  /// security alert acceptance item this review references.
  static const String sessionDeviceManifestPath =
      'docs/planning/v1.2/sprint_115_session_device_management.json';

  /// The committed 115.11 OAuth & linked identity flow that declares the OAuth
  /// acceptance items this review references.
  static const String oauthIdentityManifestPath =
      'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json';

  /// The committed 116.6 credential & secret test safety that declares the
  /// redaction control this review references.
  static const String credentialSafetyManifestPath =
      'docs/planning/v1.2/sprint_116_credential_secret_test_safety.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.18.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The eight canonical security signals the objective names.
  static const List<String> securitySignals = <String>[
    'oauth_alert',
    'vault_health',
    'session_alert',
    'permission_denial',
    'redirect_alert',
    'webhook_alert',
    'dependency_alert',
    'redaction_failure',
  ];

  /// The declared marker for a signal the committed security witnesses have no
  /// state for. It is honest on the delayed path: it declares no reference
  /// state rather than inventing one.
  static const String noReferenceState = 'no_reference_state';

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
    'docs/planning/v1.2/sprint_115_session_device_management.json',
    'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    'docs/planning/v1.2/sprint_116_security_certification_gate.json',
    'docs/planning/v1.2/sprint_116_credential_secret_test_safety.json',
  ];

  /// The distinct union of the committed security witness vocabularies, in
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
    final index = securitySignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing. Every one
  /// of the eight canonical signals draws its reference state from the committed
  /// security witness vocabulary, so no `no_reference_state` marker is needed
  /// and no upstream gap is recorded.
  static const Sprint118SecurityHealthReview
  canonicalReview = Sprint118SecurityHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118SecurityHealthEntry>[
      Sprint118SecurityHealthEntry(
        signal: 'oauth_alert',
        referenceState: 'oauth_tests',
        source:
            'docs/planning/v1.2/sprint_116_security_certification_gate.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SecurityHealthEntry(
        signal: 'vault_health',
        referenceState: 'os_secure_store',
        source: 'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SecurityHealthEntry(
        signal: 'session_alert',
        referenceState: 'security_alert',
        source: 'docs/planning/v1.2/sprint_115_session_device_management.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SecurityHealthEntry(
        signal: 'permission_denial',
        referenceState: 'permission_tests',
        source:
            'docs/planning/v1.2/sprint_116_security_certification_gate.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SecurityHealthEntry(
        signal: 'redirect_alert',
        referenceState: 'redirect_tests',
        source:
            'docs/planning/v1.2/sprint_116_security_certification_gate.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SecurityHealthEntry(
        signal: 'webhook_alert',
        referenceState: 'webhook_tests',
        source:
            'docs/planning/v1.2/sprint_116_security_certification_gate.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SecurityHealthEntry(
        signal: 'dependency_alert',
        referenceState: 'dependency_scan',
        source:
            'docs/planning/v1.2/sprint_116_security_certification_gate.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SecurityHealthEntry(
        signal: 'redaction_failure',
        referenceState: 'redaction',
        source:
            'docs/planning/v1.2/sprint_116_credential_secret_test_safety.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and security witnesses.
/// Never invents: an unreadable witness yields `null`, which the gate reports as
/// blocked rather than as a pass.
class Sprint118SecurityHealthLoader {
  const Sprint118SecurityHealthLoader();

  Sprint118SecurityHealthAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118SecurityHealthContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118SecurityHealthContract.charterManifestPath,
    );
    if (charter == null) return null;
    final securityCertification = _readJsonObject(
      Sprint118SecurityHealthContract.securityCertificationManifestPath,
    );
    if (securityCertification == null) return null;
    final tokenVault = _readJsonObject(
      Sprint118SecurityHealthContract.tokenVaultManifestPath,
    );
    if (tokenVault == null) return null;
    final sessionDevice = _readJsonObject(
      Sprint118SecurityHealthContract.sessionDeviceManifestPath,
    );
    if (sessionDevice == null) return null;
    final oauthIdentity = _readJsonObject(
      Sprint118SecurityHealthContract.oauthIdentityManifestPath,
    );
    if (oauthIdentity == null) return null;
    final credentialSafety = _readJsonObject(
      Sprint118SecurityHealthContract.credentialSafetyManifestPath,
    );
    if (credentialSafety == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118SecurityHealthContract.charterWindowMinutes;

    final readable = <String>[
      for (final source in Sprint118SecurityHealthContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118SecurityHealthAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessSecurityCertification: _stringList(
        securityCertification['acceptance_areas'],
      ),
      witnessTokenVault: _stringList(tokenVault['acceptance']),
      witnessSessionDevice: _stringList(sessionDevice['acceptance']),
      witnessOAuthIdentity: _stringList(oauthIdentity['acceptance']),
      witnessCredentialSafety: _stringList(
        credentialSafety['required_controls'],
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

class Sprint118SecurityHealthGate {
  const Sprint118SecurityHealthGate();

  /// Evaluate the canonical review against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118SecurityHealthReport evaluate() => evaluateWith(
    const Sprint118SecurityHealthLoader().loadAnchor(),
    Sprint118SecurityHealthContract.canonicalReview,
  );

  Sprint118SecurityHealthReport evaluateWith(
    Sprint118SecurityHealthAnchor? anchor,
    Sprint118SecurityHealthReview review,
  ) {
    if (anchor == null) {
      return Sprint118SecurityHealthReport(
        state: Sprint118SecurityHealthState.blocked,
        verdict: 'SPRINT_118_SECURITY_HEALTH_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118SecurityHealthContract.requiredFields,
        ),
        blockers: const <String>[
          'committed_security_health_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_security_health_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes security readings nobody
    // measured.
    if (anchor.baselineState !=
            Sprint118SecurityHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118SecurityHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118SecurityHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118SecurityHealthContract.requiredCharterVerdict) {
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
    // release, an observation describes a live OAuth alert, a real vault read,
    // a real session revocation, or a real dependency advisory that was never
    // observed.
    final delayed =
        review.releaseState ==
        Sprint118SecurityHealthContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'security_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessSecurityCertification.isEmpty ||
        anchor.witnessTokenVault.isEmpty ||
        anchor.witnessSessionDevice.isEmpty ||
        anchor.witnessOAuthIdentity.isEmpty ||
        anchor.witnessCredentialSafety.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_security_vocabulary_missing');
    }
    final vocabulary =
        Sprint118SecurityHealthContract.stateVocabulary(<List<String>>[
          anchor.witnessSecurityCertification,
          anchor.witnessTokenVault,
          anchor.witnessSessionDevice,
          anchor.witnessOAuthIdentity,
          anchor.witnessCredentialSafety,
        ]);

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118SecurityHealthContract.securitySignals.contains(signal)) {
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
            Sprint118SecurityHealthContract.noReferenceState) {
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
    for (final signal in Sprint118SecurityHealthContract.securitySignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source in Sprint118SecurityHealthContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118SecurityHealthReport(
        state: Sprint118SecurityHealthState.fail,
        verdict: 'SPRINT_118_SECURITY_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118SecurityHealthReport(
        state: Sprint118SecurityHealthState.blocked,
        verdict: 'SPRINT_118_SECURITY_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118SecurityHealthReport(
      state: Sprint118SecurityHealthState.pass,
      verdict: 'SECURITY_HEALTH_REVIEW_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
