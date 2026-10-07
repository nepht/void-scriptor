/// Fail-closed charter contract for roadmap step 118.2 -- Stability & Expansion
/// Charter.
///
/// Objective (external canonical `sprint_118.json`): fix the observation
/// `window`, the `stability_questions`, the `expansion_budget`, the `owners`,
/// the `stop_conditions`, and the `exit_criteria` before any stability work or
/// provider expansion begins.
///
/// The canonical contract is blunt about the situation this charter is written
/// against. Sprint 118 is `PLANNED_BLOCKED` with `entry_readiness`
/// `BLOCKED_BY_SPRINT_117_AND_CONNECTOR_CERTIFICATION`, step 118.1 selected the
/// delayed corrective path (`GA_DELAYED` + `CORRECTIVE_SCOPE_APPROVED`), and the
/// sprint's own `stability_rules` require `provider_expansion_requires_
/// certification: true` while `source_registry.currently_certified` is `0` of
/// `32`. A charter is therefore not allowed to promise an observation window
/// that is running, or an expansion budget that authorises connectors nobody
/// certified.
///
/// The gate is fail-closed on nine families of rules:
///
/// * Every canonical required field must be present and non-empty. A charter
///   that forgets the expansion budget is not a charter, and an absent field is
///   reported by name rather than silently skipped.
/// * The entry anchor must be a genuine `pass` on `SPRINT_118_ENTRY_READY`, and
///   a delayed anchor additionally requires the approved corrective scope. A
///   charter written against a blocked entry gate describes a sprint that may
///   not start.
/// * The window must run forward, its declared duration must equal the span it
///   actually covers, and its phases must be contiguous and tile the window
///   exactly. A window that does not add up is a plan nobody can execute.
/// * A delayed release may not report an executed observation window, and a
///   released sprint may not report an unexecuted one: the recorded state and
///   the recorded window must agree.
/// * Each stability question must be measurable, unique, drawn from the known
///   area vocabulary, and mapped to a step in the stability half of the sprint
///   (118.3--118.28). Expansion questions belong to 118.29--118.43.
/// * The expansion budget must require certification, may never authorise more
///   new connectors than are certified, and must name why it is limited. With
///   zero certified connectors the only honest budget is zero.
/// * Every declared owner scope must be owned by somebody, and every owner must
///   be unique with a known role and known scopes.
/// * Every stop condition must watch a known metric with a real threshold and a
///   real window, and must be able to contain -- a stop condition whose only
///   response is to page somebody has no way to stop anything.
/// * Every exit criterion must demand evidence, and the charter must cover every
///   canonical exit gate.
///
/// Live observation, connector certification, provider exposure, and external
/// telemetry remain `DEFERRED-EXTERNAL`; this charter defines the contract and
/// executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a charter evaluation can rest in. `blocked` is the honest
/// resting state for "this charter cannot yet be executed", and it is distinct
/// from `fail`, which means the charter contradicts itself.
enum Sprint118CharterState { pass, fail, blocked }

/// One planned phase of the observation window. A phase is a promise about a
/// stretch of time, so it carries the exit criterion that must hold to leave it.
class Sprint118CharterPhase {
  const Sprint118CharterPhase({
    required this.phaseId,
    required this.startEpochMs,
    required this.endEpochMs,
    required this.exitCriterion,
  });

  final String phaseId;
  final int startEpochMs;
  final int endEpochMs;
  final String exitCriterion;

  int get durationDays =>
      (endEpochMs - startEpochMs) ~/ Sprint118CharterContract.dayInMilliseconds;
}

/// The planned observation window. `executed` is not decoration: on the delayed
/// path it must be false, because no release ran and therefore nothing was
/// observed.
class Sprint118CharterWindow {
  const Sprint118CharterWindow({
    required this.windowId,
    required this.startEpochMs,
    required this.endEpochMs,
    required this.durationDays,
    required this.phases,
    required this.executed,
  });

  final String windowId;
  final int startEpochMs;
  final int endEpochMs;
  final int durationDays;
  final List<Sprint118CharterPhase> phases;
  final bool executed;

  int get derivedDurationDays =>
      (endEpochMs - startEpochMs) ~/ Sprint118CharterContract.dayInMilliseconds;

  /// Phases in chronological order, so coverage can be checked deterministically
  /// regardless of the order the charter happens to list them in.
  List<Sprint118CharterPhase> get orderedPhases {
    final ordered = List<Sprint118CharterPhase>.of(phases);
    ordered.sort((a, b) => a.startEpochMs.compareTo(b.startEpochMs));
    return ordered;
  }
}

/// One stability question the charter commits to answering, with the sprint step
/// that owns the answer and the signal that will measure it.
class Sprint118StabilityQuestion {
  const Sprint118StabilityQuestion({
    required this.questionId,
    required this.area,
    required this.step,
    required this.question,
    required this.measurable,
    required this.signal,
  });

  final String questionId;
  final String area;
  final String step;
  final String question;
  final bool measurable;
  final String signal;
}

/// The expansion budget. On a delayed release with zero certified connectors the
/// only honest budget is zero new certified connectors; the budget must say so
/// and must say why.
class Sprint118ExpansionBudget {
  const Sprint118ExpansionBudget({
    required this.maxNewCertifiedConnectors,
    required this.requiresCertification,
    required this.currentlyCertified,
    required this.currentlyLimited,
    required this.registeredProviders,
    required this.blockedReason,
  });

  final int maxNewCertifiedConnectors;
  final bool requiresCertification;
  final int currentlyCertified;
  final int currentlyLimited;
  final int registeredProviders;
  final String blockedReason;
}

/// An owner with the scopes that owner is accountable for.
class Sprint118CharterOwner {
  const Sprint118CharterOwner({
    required this.ownerId,
    required this.role,
    required this.scopes,
  });

  final String ownerId;
  final String role;
  final List<String> scopes;
}

/// A stop condition: a metric, a threshold, a window, and an action that can
/// actually stop something.
class Sprint118CharterStopCondition {
  const Sprint118CharterStopCondition({
    required this.stopId,
    required this.metricId,
    required this.operator,
    required this.threshold,
    required this.windowMinutes,
    required this.action,
  });

  final String stopId;
  final String metricId;
  final String operator;
  final double threshold;
  final int windowMinutes;
  final String action;
}

/// An exit criterion: what must be true, and that evidence is required for it.
class Sprint118CharterExitCriterion {
  const Sprint118CharterExitCriterion({
    required this.criterionId,
    required this.gate,
    required this.description,
    required this.requiresEvidence,
  });

  final String criterionId;
  final String gate;
  final String description;
  final bool requiresEvidence;
}

/// The six canonical fields the step is made of, held together so the gate can
/// evaluate the charter as one object instead of as loose parts.
class Sprint118StabilityExpansionCharter {
  const Sprint118StabilityExpansionCharter({
    required this.releaseState,
    required this.window,
    required this.questions,
    required this.expansionBudget,
    required this.owners,
    required this.stopConditions,
    required this.exitCriteria,
  });

  /// The release state this charter is written against. It must agree with the
  /// committed entry anchor, so a charter cannot quietly describe a release that
  /// did not happen.
  final String releaseState;

  final Sprint118CharterWindow window;
  final List<Sprint118StabilityQuestion> questions;
  final Sprint118ExpansionBudget expansionBudget;
  final List<Sprint118CharterOwner> owners;
  final List<Sprint118CharterStopCondition> stopConditions;
  final List<Sprint118CharterExitCriterion> exitCriteria;
}

/// What the committed 118.1 witnesses actually say. A charter is only as honest
/// as the entry gate it builds on.
class Sprint118CharterAnchor {
  const Sprint118CharterAnchor({
    required this.entryState,
    required this.entryVerdict,
    required this.releaseState,
    required this.correctiveScopeApproved,
    required this.providerCount,
  });

  final String entryState;
  final String entryVerdict;
  final String releaseState;

  /// `null` when no corrective scope approval is recorded -- undetermined, never
  /// consent.
  final bool? correctiveScopeApproved;

  final int providerCount;
}

/// The measured result. `pass` means the charter holds together; `blocked` means
/// it cannot be executed yet; `fail` means it contradicts itself.
class Sprint118CharterReport {
  const Sprint118CharterReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
  });

  final Sprint118CharterState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;

  /// Whether the charter may be executed. Only a genuine `pass` allows it.
  bool get charterExecutable => state == Sprint118CharterState.pass;

  String get externalGates => Sprint118CharterContract.externalGates;

  /// No live observation ran on the delayed path, and this charter never claims
  /// otherwise.
  bool get liveObservationExecuted => false;
}

/// The fixed vocabulary of step 118.2, kept in one place so the loader, the gate,
/// and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118CharterContract {
  const Sprint118CharterContract._();

  static const String canonicalStep = '118.2';
  static const String title = 'Stability & Expansion Charter';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.1 witnesses this charter is anchored to.
  static const String entryManifestPath =
      'docs/planning/v1.3/sprint_118_entry_gate.json';
  static const String correctiveScopePath =
      'docs/planning/v1.3/sprint_118_corrective_scope_approval.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict the entry anchor must carry for the charter to be executable.
  static const String requiredEntryVerdict = 'SPRINT_118_ENTRY_READY';
  static const String requiredEntryState = 'pass';
  static const String delayedReleaseState = 'GA_DELAYED';
  static const String releasedReleaseState = 'GA_RELEASED';

  static const int dayInMilliseconds = 86400000;

  /// The six canonical fields from `sprint_118.json` step 118.2.
  static const List<String> requiredFields = <String>[
    'window',
    'stability_questions',
    'expansion_budget',
    'owners',
    'stop_conditions',
    'exit_criteria',
  ];

  /// Every owner scope the charter must place with somebody.
  static const List<String> requiredOwnerScopes = <String>[
    'charter',
    'stability_question',
    'expansion_budget',
    'stop_condition',
    'exit_criterion',
  ];

  static const List<String> knownOwnerScopes = <String>[
    'charter',
    'stability_question',
    'expansion_budget',
    'stop_condition',
    'exit_criterion',
    'incident',
  ];

  static const List<String> knownAreas = <String>[
    'connection_health',
    'oauth_reauth',
    'quota_storage',
    'sync_backup_recovery',
    'ai_provider',
    'billing_entitlement',
    'security',
    'privacy',
    'novel_character_boundary',
    'accessibility',
    'performance',
    'provider_outage_recovery',
  ];

  static const List<String> knownOperators = <String>['gt', 'gte', 'lt', 'lte'];

  static const List<String> knownMetrics = <String>[
    'crash_rate',
    'error_rate',
    'auth_success',
    'sync_integrity_issue',
    'privacy_leak',
    'quota_mismatch',
    'data_loss',
  ];

  /// Actions that can actually contain a problem. A stop condition whose only
  /// response is `page_oncall` has no way to stop anything, so the gate refuses
  /// a stop condition that lists no containment action.
  static const List<String> containmentActions = <String>[
    'halt_rollout',
    'disable_connector',
    'rollback_stage',
    'quarantine_connector',
  ];

  static const List<String> knownActions = <String>[
    'halt_rollout',
    'disable_connector',
    'rollback_stage',
    'quarantine_connector',
    'page_oncall',
  ];

  /// Every exit gate the charter must name. These are the canonical exit
  /// criteria a stability-and-expansion charter has to close.
  static const List<String> requiredExitGates = <String>[
    'release_state_confirmed',
    'stability_questions_answered',
    'expansion_budget_respected',
    'incidents_resolved_or_contained',
    'maintenance_decision_recorded',
    'regression_evidence_present',
  ];

  static const List<String> knownExitGates = <String>[
    'release_state_confirmed',
    'stability_questions_answered',
    'expansion_budget_respected',
    'incidents_resolved_or_contained',
    'maintenance_decision_recorded',
    'regression_evidence_present',
    'rollback_ready',
  ];

  /// The stability half of the sprint: steps 118.3--118.28 answer stability
  /// questions. Expansion lives in 118.29--118.43.
  static const int firstStabilityStepNumber = 3;
  static const int lastStabilityStepNumber = 28;

  /// The canonical charter, declared here as the single source of truth. The
  /// gate evaluates exactly this object, and the emitter writes exactly this
  /// object, so the record cannot be made to agree with itself.
  static const Sprint118StabilityExpansionCharter canonicalCharter =
      Sprint118StabilityExpansionCharter(
        releaseState: delayedReleaseState,
        window: Sprint118CharterWindow(
          windowId: 'stability_observation_window',
          startEpochMs: 1794787200000,
          endEpochMs: 1798416000000,
          durationDays: 42,
          executed: false,
          phases: <Sprint118CharterPhase>[
            Sprint118CharterPhase(
              phaseId: 'phase_internal',
              startEpochMs: 1794787200000,
              endEpochMs: 1795996800000,
              exitCriterion: 'no_sev1_for_72h',
            ),
            Sprint118CharterPhase(
              phaseId: 'phase_alpha',
              startEpochMs: 1795996800000,
              endEpochMs: 1797206400000,
              exitCriterion: 'no_sev1_for_72h',
            ),
            Sprint118CharterPhase(
              phaseId: 'phase_waitlist',
              startEpochMs: 1797206400000,
              endEpochMs: 1798416000000,
              exitCriterion: 'no_sev1_for_72h',
            ),
          ],
        ),
        questions: <Sprint118StabilityQuestion>[
          Sprint118StabilityQuestion(
            questionId: 'q_connection_health',
            area: 'connection_health',
            step: '118.7',
            question:
                'Apakah connect, expiry, revoke, degraded, outage, latency, '
                'dan disconnect cleanup per connector version tetap sehat?',
            measurable: true,
            signal: 'connect_success',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_oauth_reauth',
            area: 'oauth_reauth',
            step: '118.8',
            question:
                'Apakah callback, state, rotation, reauth, scope change, dan '
                'provider revoke selesai tanpa kehilangan sesi pengguna?',
            measurable: true,
            signal: 'reauth_completion',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_quota_storage',
            area: 'quota_storage',
            step: '118.9',
            question:
                'Apakah kuota yang ditampilkan cocok dengan pemakaian yang '
                'dilaporkan, tanpa angka basi atau presisi palsu?',
            measurable: true,
            signal: 'quota_match',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_sync_backup_recovery',
            area: 'sync_backup_recovery',
            step: '118.10',
            question:
                'Apakah queue, transfer, retry, conflict, backup terenkripsi, '
                'dan restore mempertahankan integritas data pengguna?',
            measurable: true,
            signal: 'restore_success',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_ai_provider',
            area: 'ai_provider',
            step: '118.11',
            question:
                'Apakah discovery, job, cancellation, usage, cost, fallback, '
                'dan privacy destination AI provider konsisten?',
            measurable: true,
            signal: 'job_success',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_billing_entitlement',
            area: 'billing_entitlement',
            step: '118.12',
            question:
                'Apakah checkout, webhook, idempotency, invoice, entitlement, '
                'dan refund tetap benar tanpa pembayaran ganda?',
            measurable: true,
            signal: 'entitlement',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_security',
            area: 'security',
            step: '118.18',
            question:
                'Apakah OAuth, vault, session, permission, redirect, webhook, '
                'dan redaction log tetap aman tanpa kebocoran rahasia?',
            measurable: true,
            signal: 'redaction_failure',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_privacy',
            area: 'privacy',
            step: '118.19',
            question:
                'Apakah consent, destination, retention, deletion, disconnect, '
                'dan telemetry control tidak melewatkan data pengguna?',
            measurable: true,
            signal: 'destination_issue',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_novel_character_boundary',
            area: 'novel_character_boundary',
            step: '118.20',
            question:
                'Apakah connector global tidak pernah mendapat akses otomatis '
                'ke data Novel atau Character dan transfer selalu eksplisit?',
            measurable: true,
            signal: 'transfer_consent',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_accessibility',
            area: 'accessibility',
            step: '118.15',
            question:
                'Apakah seluruh alur dapat diselesaikan dengan keyboard dan '
                'reader layar pada kontras yang memenuhi ambang?',
            measurable: true,
            signal: 'keyboard_blocker',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_performance',
            area: 'performance',
            step: '118.16',
            question:
                'Apakah render, refresh, scan lokal, chart, memori, dan cache '
                'tetap dalam anggaran resource?',
            measurable: true,
            signal: 'memory',
          ),
          Sprint118StabilityQuestion(
            questionId: 'q_provider_outage_recovery',
            area: 'provider_outage_recovery',
            step: '118.17',
            question:
                'Apakah timeout, circuit breaker, retry-after, queue recovery, '
                'dan kill switch memulihkan layanan tanpa kehilangan data?',
            measurable: true,
            signal: 'provider_recovery',
          ),
        ],
        expansionBudget: Sprint118ExpansionBudget(
          maxNewCertifiedConnectors: 0,
          requiresCertification: true,
          currentlyCertified: 0,
          currentlyLimited: 0,
          registeredProviders: 32,
          blockedReason:
              'no_certified_connector:0_of_32; expansion requires versioned '
              'certification evidence (118.39/118.42) before any connector may '
              'be added',
        ),
        owners: <Sprint118CharterOwner>[
          Sprint118CharterOwner(
            ownerId: 'stability-owner',
            role: 'stability_owner',
            scopes: <String>[
              'stability_question',
              'stop_condition',
              'exit_criterion',
            ],
          ),
          Sprint118CharterOwner(
            ownerId: 'expansion-owner',
            role: 'expansion_owner',
            scopes: <String>['expansion_budget'],
          ),
          Sprint118CharterOwner(
            ownerId: 'release-owner',
            role: 'release_owner',
            scopes: <String>['charter', 'exit_criterion'],
          ),
        ],
        stopConditions: <Sprint118CharterStopCondition>[
          Sprint118CharterStopCondition(
            stopId: 'stability_stop_crash',
            metricId: 'crash_rate',
            operator: 'gt',
            threshold: 0.01,
            windowMinutes: 1440,
            action: 'disable_connector',
          ),
          Sprint118CharterStopCondition(
            stopId: 'stability_stop_auth',
            metricId: 'auth_success',
            operator: 'lt',
            threshold: 0.95,
            windowMinutes: 60,
            action: 'halt_rollout',
          ),
          Sprint118CharterStopCondition(
            stopId: 'stability_stop_sync_integrity',
            metricId: 'sync_integrity_issue',
            operator: 'gt',
            threshold: 0,
            windowMinutes: 60,
            action: 'rollback_stage',
          ),
          Sprint118CharterStopCondition(
            stopId: 'stability_stop_privacy',
            metricId: 'privacy_leak',
            operator: 'gt',
            threshold: 0,
            windowMinutes: 60,
            action: 'quarantine_connector',
          ),
          Sprint118CharterStopCondition(
            stopId: 'stability_stop_error_rate',
            metricId: 'error_rate',
            operator: 'gt',
            threshold: 0.02,
            windowMinutes: 60,
            action: 'halt_rollout',
          ),
        ],
        exitCriteria: <Sprint118CharterExitCriterion>[
          Sprint118CharterExitCriterion(
            criterionId: 'exit_release_state',
            gate: 'release_state_confirmed',
            description:
                'Release state is re-confirmed from the committed 117/118 '
                'evidence and never inferred from a local test.',
            requiresEvidence: true,
          ),
          Sprint118CharterExitCriterion(
            criterionId: 'exit_questions',
            gate: 'stability_questions_answered',
            description:
                'Every declared stability question has a recorded answer or an '
                'explicit DEFERRED-EXTERNAL with evidence.',
            requiresEvidence: true,
          ),
          Sprint118CharterExitCriterion(
            criterionId: 'exit_expansion_budget',
            gate: 'expansion_budget_respected',
            description:
                'No connector was certified or exposed beyond the recorded '
                'expansion budget.',
            requiresEvidence: true,
          ),
          Sprint118CharterExitCriterion(
            criterionId: 'exit_incidents',
            gate: 'incidents_resolved_or_contained',
            description:
                'Every critical incident is resolved or its connector is '
                'disabled with a recorded recovery path.',
            requiresEvidence: true,
          ),
          Sprint118CharterExitCriterion(
            criterionId: 'exit_maintenance',
            gate: 'maintenance_decision_recorded',
            description:
                'The maintenance release decision (BUILD_1_3_1 / NO_PATCH) is '
                'recorded with artifact, upgrade, and rollback evidence.',
            requiresEvidence: true,
          ),
          Sprint118CharterExitCriterion(
            criterionId: 'exit_regression',
            gate: 'regression_evidence_present',
            description:
                'The maintenance regression matrix ran green over the critical '
                'Account Center workflows.',
            requiresEvidence: true,
          ),
        ],
      );

  /// Parse a canonical step id such as `118.7` into its step number, or `null`
  /// when the id is not a well-formed step id.
  static int? stepNumber(String step) {
    final trimmed = step.trim();
    final parts = trimmed.split('.');
    if (parts.length != 2 || parts[0] != '118') return null;
    return int.tryParse(parts[1]);
  }
}

/// Reads the committed 118.1 witnesses. Never invents: an unreadable witness
/// yields `null`, which the gate reports as blocked rather than as a pass.
class Sprint118CharterLoader {
  const Sprint118CharterLoader();

  Sprint118CharterAnchor? loadAnchor() {
    final entry = _readJsonObject(Sprint118CharterContract.entryManifestPath);
    if (entry == null) return null;

    final corrective = _readJsonObject(
      Sprint118CharterContract.correctiveScopePath,
    );
    final bool? correctiveApproved = corrective == null
        ? null
        : (corrective['corrective_scope_approved'] == true ||
              _text(corrective['status']).toUpperCase() ==
                  'CORRECTIVE_SCOPE_APPROVED');

    return Sprint118CharterAnchor(
      entryState: _text(entry['state']),
      entryVerdict: _text(entry['verdict']),
      releaseState: _text(entry['release_state']),
      correctiveScopeApproved: correctiveApproved,
      providerCount: _int(entry['provider_count']),
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

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class Sprint118StabilityExpansionCharterGate {
  const Sprint118StabilityExpansionCharterGate();

  /// Evaluate the canonical charter against committed evidence. This is the
  /// entry point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118CharterReport evaluate() => evaluateWith(
    const Sprint118CharterLoader().loadAnchor(),
    Sprint118CharterContract.canonicalCharter,
  );

  Sprint118CharterReport evaluateWith(
    Sprint118CharterAnchor? anchor,
    Sprint118StabilityExpansionCharter charter,
  ) {
    if (anchor == null) {
      return Sprint118CharterReport(
        state: Sprint118CharterState.blocked,
        verdict: 'SPRINT_118_CHARTER_EVIDENCE_UNREADABLE',
        releaseState: charter.releaseState,
        missingFields: List<String>.from(
          Sprint118CharterContract.requiredFields,
        ),
        blockers: const <String>['committed_entry_evidence_unreadable'],
        openItems: const <String>['committed_entry_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final missing = <String>[];

    // (1) Every canonical field must be present and non-empty.
    final fieldCounts = <String, int>{
      'window': 1,
      'stability_questions': charter.questions.length,
      'expansion_budget': 1,
      'owners': charter.owners.length,
      'stop_conditions': charter.stopConditions.length,
      'exit_criteria': charter.exitCriteria.length,
    };
    for (final field in Sprint118CharterContract.requiredFields) {
      if ((fieldCounts[field] ?? 0) == 0) missing.add(field);
    }
    if (missing.isNotEmpty) {
      return Sprint118CharterReport(
        state: Sprint118CharterState.blocked,
        verdict: 'SPRINT_118_CHARTER_FIELDS_MISSING',
        releaseState: charter.releaseState,
        missingFields: missing,
        blockers: <String>[for (final field in missing) 'field_missing:$field'],
        openItems: <String>[
          for (final field in missing) 'field_missing:$field',
        ],
      );
    }

    // (2) The entry anchor must be a genuine pass, and a delayed anchor needs
    // the approved corrective scope. An absent approval is never consent.
    if (anchor.entryState != Sprint118CharterContract.requiredEntryState ||
        anchor.entryVerdict != Sprint118CharterContract.requiredEntryVerdict) {
      blockers.add('entry_gate_not_passed:${anchor.entryVerdict}');
    }
    if (anchor.releaseState != charter.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'charter=${charter.releaseState}',
      );
    }
    if (anchor.releaseState == Sprint118CharterContract.delayedReleaseState &&
        anchor.correctiveScopeApproved != true) {
      blockers.add('corrective_scope_not_approved');
    }

    // (3) The window must run forward, add up, and tile exactly.
    final window = charter.window;
    if (window.startEpochMs >= window.endEpochMs) {
      violations.add('window_not_forward');
    }
    if (window.durationDays != window.derivedDurationDays) {
      violations.add(
        'window_duration_mismatch:declared=${window.durationDays}:'
        'derived=${window.derivedDurationDays}',
      );
    }
    if (window.phases.isEmpty) {
      violations.add('window_has_no_phases');
    } else {
      final ordered = window.orderedPhases;
      if (ordered.first.startEpochMs != window.startEpochMs) {
        violations.add('window_phase_gap:start');
      }
      if (ordered.last.endEpochMs != window.endEpochMs) {
        violations.add('window_phase_gap:end');
      }
      for (var i = 1; i < ordered.length; i++) {
        if (ordered[i].startEpochMs != ordered[i - 1].endEpochMs) {
          violations.add('window_phase_gap:${ordered[i].phaseId}');
        }
      }
      for (final phase in ordered) {
        if (phase.exitCriterion.trim().isEmpty) {
          violations.add('window_phase_no_exit_criterion:${phase.phaseId}');
        }
        if (phase.endEpochMs <= phase.startEpochMs) {
          violations.add('window_phase_not_forward:${phase.phaseId}');
        }
      }
    }

    // (4) The recorded window state must agree with the release state: a delayed
    // release observed nothing, and a released sprint must be observing.
    if (anchor.releaseState == Sprint118CharterContract.delayedReleaseState &&
        window.executed) {
      violations.add('observation_window_executed_without_release');
    }
    if (anchor.releaseState == Sprint118CharterContract.releasedReleaseState &&
        !window.executed) {
      blockers.add('observation_window_not_active');
    }

    // (5) Stability questions must be measurable, unique, known, and owned by
    // the stability half of the sprint.
    final seenQuestionIds = <String>{};
    for (final question in charter.questions) {
      if (question.questionId.trim().isEmpty) {
        violations.add('question_blank_id');
      } else if (!seenQuestionIds.add(question.questionId)) {
        violations.add('question_duplicate_id:${question.questionId}');
      }
      if (question.question.trim().isEmpty) {
        violations.add('question_blank_text:${question.questionId}');
      }
      if (!question.measurable) {
        violations.add('question_not_measurable:${question.questionId}');
      }
      if (!Sprint118CharterContract.knownAreas.contains(question.area)) {
        violations.add('question_unknown_area:${question.questionId}');
      }
      if (question.signal.trim().isEmpty) {
        violations.add('question_no_signal:${question.questionId}');
      }
      final stepNumber = Sprint118CharterContract.stepNumber(question.step);
      if (stepNumber == null ||
          stepNumber < Sprint118CharterContract.firstStabilityStepNumber ||
          stepNumber > Sprint118CharterContract.lastStabilityStepNumber) {
        violations.add('question_step_out_of_stability_range:${question.step}');
      }
    }

    // (6) The expansion budget may never authorise more than is certified, must
    // require certification, and must say why it is limited.
    final budget = charter.expansionBudget;
    if (!budget.requiresCertification) {
      violations.add('expansion_budget_allows_uncertified_expansion');
    }
    if (budget.maxNewCertifiedConnectors < 0) {
      violations.add('expansion_budget_negative');
    }
    if (budget.maxNewCertifiedConnectors > budget.currentlyCertified) {
      violations.add(
        'expansion_budget_exceeds_certified:'
        '${budget.maxNewCertifiedConnectors}:${budget.currentlyCertified}',
      );
    }
    if (budget.maxNewCertifiedConnectors == 0 &&
        budget.blockedReason.trim().isEmpty) {
      violations.add('expansion_budget_limited_without_reason');
    }
    if (budget.registeredProviders != anchor.providerCount) {
      violations.add(
        'expansion_budget_provider_count_mismatch:'
        'charter=${budget.registeredProviders}:anchor=${anchor.providerCount}',
      );
    }

    // (7) Every declared scope must be owned, and every owner must be known.
    final ownedScopes = <String>{};
    final seenOwnerIds = <String>{};
    for (final owner in charter.owners) {
      if (owner.ownerId.trim().isEmpty) {
        violations.add('owner_blank_id');
      } else if (!seenOwnerIds.add(owner.ownerId)) {
        violations.add('owner_duplicate_id:${owner.ownerId}');
      }
      if (owner.role.trim().isEmpty) {
        violations.add('owner_blank_role:${owner.ownerId}');
      }
      for (final scope in owner.scopes) {
        if (!Sprint118CharterContract.knownOwnerScopes.contains(scope)) {
          violations.add('owner_unknown_scope:${owner.ownerId}:$scope');
        }
        ownedScopes.add(scope);
      }
    }
    for (final scope in Sprint118CharterContract.requiredOwnerScopes) {
      if (!ownedScopes.contains(scope)) {
        violations.add('owner_scope_unowned:$scope');
      }
    }

    // (8) A stop condition must be able to stop something.
    final seenStopIds = <String>{};
    for (final stop in charter.stopConditions) {
      if (stop.stopId.trim().isEmpty) {
        violations.add('stop_condition_blank_id');
      } else if (!seenStopIds.add(stop.stopId)) {
        violations.add('stop_condition_duplicate_id:${stop.stopId}');
      }
      if (!Sprint118CharterContract.knownMetrics.contains(stop.metricId)) {
        violations.add('stop_condition_unknown_metric:${stop.metricId}');
      }
      if (!Sprint118CharterContract.knownOperators.contains(stop.operator)) {
        violations.add('stop_condition_unknown_operator:${stop.operator}');
      }
      if (stop.windowMinutes <= 0) {
        violations.add('stop_condition_zero_window:${stop.stopId}');
      }
      if (stop.action.trim().isEmpty) {
        violations.add('stop_condition_blank_action:${stop.stopId}');
      } else if (!Sprint118CharterContract.knownActions.contains(stop.action)) {
        violations.add('stop_condition_unknown_action:${stop.action}');
      } else if (!Sprint118CharterContract.containmentActions.contains(
        stop.action,
      )) {
        violations.add('stop_condition_page_only:${stop.stopId}');
      }
    }

    // (9) Every exit criterion must demand evidence, and every canonical exit
    // gate must be named.
    final coveredExitGates = <String>{};
    final seenCriterionIds = <String>{};
    for (final criterion in charter.exitCriteria) {
      if (criterion.criterionId.trim().isEmpty) {
        violations.add('exit_criterion_blank_id');
      } else if (!seenCriterionIds.add(criterion.criterionId)) {
        violations.add('exit_criterion_duplicate_id:${criterion.criterionId}');
      }
      if (!criterion.requiresEvidence) {
        violations.add(
          'exit_criterion_without_evidence:${criterion.criterionId}',
        );
      }
      if (!Sprint118CharterContract.knownExitGates.contains(criterion.gate)) {
        violations.add('exit_criterion_unknown_gate:${criterion.gate}');
      }
      coveredExitGates.add(criterion.gate);
    }
    for (final gate in Sprint118CharterContract.requiredExitGates) {
      if (!coveredExitGates.contains(gate)) {
        violations.add('exit_gate_uncovered:$gate');
      }
    }

    final openItems = <String>[...violations, ...blockers];

    if (violations.isNotEmpty) {
      return Sprint118CharterReport(
        state: Sprint118CharterState.fail,
        verdict: 'SPRINT_118_CHARTER_EVIDENCE_VIOLATION',
        releaseState: charter.releaseState,
        missingFields: missing,
        violations: violations,
        blockers: blockers,
        openItems: openItems,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118CharterReport(
        state: Sprint118CharterState.blocked,
        verdict: 'SPRINT_118_CHARTER_BLOCKED_UPSTREAM',
        releaseState: charter.releaseState,
        missingFields: missing,
        violations: violations,
        blockers: blockers,
        openItems: openItems,
      );
    }
    return Sprint118CharterReport(
      state: Sprint118CharterState.pass,
      verdict: 'CHARTER_COMPLETE_LOCAL',
      releaseState: charter.releaseState,
    );
  }
}
