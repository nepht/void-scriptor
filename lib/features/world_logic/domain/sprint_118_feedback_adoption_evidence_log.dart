/// Fail-closed feedback and adoption evidence log for roadmap step 118.21 --
/// Feedback & Adoption Evidence Log.
///
/// Objective (external canonical `sprint_118.json`): record workflow outcomes,
/// friction, support needs, and requested connectors *without* treating a
/// request as a commitment. The canonical required-field list is exactly eight
/// items: `evidence_id`, `source`, `consent`, `workflow`, `outcome`, `friction`,
/// `request`, and `limitations`.
///
/// This is the log the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// keeps before any live participant feedback or adoption telemetry exists. The
/// gate answers a single question: does the declared log carry, for every
/// canonical workflow, a record with all eight required fields, a known consent
/// basis, a known outcome, a well-formed request, and a committed, readable
/// evidence source -- and does every request stay a request?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A log built on a
///   baseline that did not freeze describes feedback nobody measured.
/// * The committed 118.2 charter anchor must be a genuine complete charter
///   (`pass` on `CHARTER_COMPLETE_LOCAL`). A log written outside the frozen
///   stability charter has no window to belong to.
/// * The log's release state must agree with the baseline anchor.
/// * On the delayed path no live adoption may be claimed: neither the workflow
///   witness may report an executed end-user validation nor any entry may carry
///   a live workflow outcome, and no entry may claim the committed participant
///   consent basis.
/// * Every canonical workflow must be present exactly once, must carry all
///   eight required fields non-blank, must name a known consent basis and a
///   known outcome, and must cite a committed, readable evidence source.
/// * **A request is never a commitment.** Every entry records a request -- a
///   requested connector, a support need, or the no-request marker -- and the
///   gate refuses any entry that treats that request as a commitment, and any
///   request that is neither the no-request marker nor a `requested:` connector.
///
/// The workflow vocabulary and the outcome vocabulary are *derived from the
/// committed 114.23 workflow-outcome-review witness* (its `workflows` and
/// `dimensions`), and the consent vocabulary is *derived from the committed
/// 113.3 validation-cohort-consent witness* (its `consent_type`), not copied by
/// hand, so the log and its witnesses cannot drift apart silently. The delayed
/// path adds `no_live_outcome` to the outcome vocabulary and
/// `no_participant_consent` to the consent vocabulary: with no live participant,
/// the only honest outcome is that there is none and the only honest consent is
/// that none was collected.
///
/// Live participant feedback, adoption telemetry, support-channel operations,
/// connector certification, provider exposure, release authorization, and
/// publication remain `DEFERRED-EXTERNAL`; this log freezes local declared state
/// and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a log evaluation can rest in. `blocked` is the honest
/// resting state for "this log cannot yet be trusted", and it is distinct from
/// `fail`, which means the log contradicts its own evidence.
enum Sprint118FeedbackLogState { pass, fail, blocked }

/// One feedback/adoption evidence record: the declared registration for a
/// single canonical workflow, with the eight required fields it must carry.
///
/// `requestIsCommitment` is deliberately *not* one of the eight required
/// fields; it is the flag the gate refuses when set, so that a request can be
/// recorded while never being read as a promise.
class Sprint118FeedbackEntry {
  const Sprint118FeedbackEntry({
    required this.workflow,
    required this.evidenceId,
    required this.source,
    required this.consent,
    required this.outcome,
    required this.friction,
    required this.request,
    required this.limitations,
    this.requestIsCommitment = false,
  });

  /// The canonical workflow this record registers, drawn from the workflow
  /// vocabulary.
  final String workflow;

  /// The evidence identifier. Stable and declared; no live participant is
  /// implied.
  final String evidenceId;

  /// The committed evidence source for this workflow. Must be readable.
  final String source;

  /// The declared consent basis. On the delayed path this must be the
  /// no-participant marker; claiming the committed explicit consent basis is
  /// refused because no participant consented.
  final String consent;

  /// The declared workflow outcome. On the delayed path this must be
  /// `no_live_outcome`; any live outcome is refused because no adoption ran.
  final String outcome;

  /// The declared friction, or the no-friction marker. Declared local
  /// observation, not live telemetry.
  final String friction;

  /// The declared request: a `requested:` connector, a support need, or the
  /// no-request marker. A request is never a commitment.
  final String request;

  /// The declared limitations. Must not be empty.
  final List<String> limitations;

  /// Whether this record treats its request as a commitment. The gate refuses
  /// `true`: a request is a request, never a promise.
  final bool requestIsCommitment;

  /// The eight required fields as a name -> value map, so the gate can test
  /// blankness uniformly.
  Map<String, String> get fields => <String, String>{
    'evidence_id': evidenceId,
    'source': source,
    'consent': consent,
    'workflow': workflow,
    'outcome': outcome,
    'friction': friction,
    'request': request,
    'limitations': limitations.join('; '),
  };
}

/// The declared log. `entries` is the evidence surface for the delayed
/// corrective path; on that path no entry may register a live outcome.
class Sprint118FeedbackAdoptionLog {
  const Sprint118FeedbackAdoptionLog({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118FeedbackEntry> entries;

  List<String> get workflows => <String>[
    for (final entry in entries) entry.workflow,
  ];
}

/// What the committed witnesses actually say. A log is only as honest as the
/// witnesses it reads.
class Sprint118FeedbackAdoptionAnchor {
  const Sprint118FeedbackAdoptionAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.liveAdoptionExecuted,
    required this.workflows,
    required this.outcomes,
    required this.consentType,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;

  /// Whether the committed workflow witness claims an end-user validation was
  /// executed. On the delayed path this must stay `false`.
  final bool liveAdoptionExecuted;

  /// The workflow vocabulary the committed 114.23 witness declares.
  final List<String> workflows;

  /// The outcome-dimension vocabulary the committed 114.23 witness declares.
  final List<String> outcomes;

  /// The consent basis the committed 113.3 witness declares.
  final String consentType;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the log is well-formed; `blocked` means it
/// cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118FeedbackAdoptionReport {
  const Sprint118FeedbackAdoptionReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredWorkflows = const <String>[],
    this.entryCount = 0,
    this.outcomeVocabulary = const <String>[],
  });

  final Sprint118FeedbackLogState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredWorkflows;
  final int entryCount;
  final List<String> outcomeVocabulary;

  /// Whether the log may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get logVerified => state == Sprint118FeedbackLogState.pass;

  String get externalGates => Sprint118FeedbackAdoptionContract.externalGates;
}

/// The fixed vocabulary of step 118.21, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118FeedbackAdoptionContract {
  const Sprint118FeedbackAdoptionContract._();

  static const String canonicalStep = '118.21';
  static const String title = 'Feedback & Adoption Evidence Log';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_feedback_adoption_evidence_log.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this log is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter this log is anchored to.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 114.23 workflow-outcome-review witness that declares the
  /// workflow and outcome vocabularies.
  static const String workflowManifestPath =
      'docs/planning/v1.2/sprint_114_workflow_outcome_review.json';

  /// The committed 113.3 validation-cohort-consent witness that declares the
  /// consent basis.
  static const String consentManifestPath =
      'docs/planning/v1.2/sprint_113_validation_cohort_consent.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The product version the log is declared against.
  static const String baseVersion = '1.3.1';

  /// The eight canonical required fields from `sprint_118.json` step 118.21.
  static const List<String> requiredFields = <String>[
    'evidence_id',
    'source',
    'consent',
    'workflow',
    'outcome',
    'friction',
    'request',
    'limitations',
  ];

  /// The five canonical workflows the objective names, matching the committed
  /// 114.23 witness `workflows`. The gate verifies membership against the
  /// witness.
  static const List<String> canonicalWorkflows = <String>[
    'writer',
    'lore',
    'simulation',
    'sharing',
    'publishing',
  ];

  /// The outcome an entry declares when no live adoption has occurred. On the
  /// delayed path this is the only honest outcome.
  static const String noLiveOutcome = 'no_live_outcome';

  /// The consent an entry declares when no participant has consented. On the
  /// delayed path this is the only honest consent.
  static const String noParticipantConsent = 'no_participant_consent';

  /// The friction an entry declares when none was recorded.
  static const String noFrictionRecorded = 'none_recorded';

  /// The request an entry declares when nothing was requested.
  static const String noRequestRecorded = 'no_request_recorded';

  /// The prefix a recorded request must carry. A request is a request, never a
  /// commitment.
  static const String requestPrefix = 'requested:';

  /// The marker the committed workflow witness uses for deferred execution.
  static const String deferredMarker = 'DEFERRED-EXTERNAL';

  /// The committed evidence source registered for each canonical workflow.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_113_writer_workflow_validation.json',
    'docs/planning/v1.2/sprint_113_lore_encyclopedia_workflow_validation.json',
    'docs/planning/v1.2/sprint_113_world_simulation_workflow_validation.json',
    'docs/planning/v1.2/sprint_112_end_to_end_beta_reader_workflow.json',
    'docs/planning/v1.2/sprint_112_end_to_end_publishing_workflow.json',
  ];

  /// The outcome vocabulary derived from the committed 114.23 witness: the
  /// declared outcome dimensions plus the no-live-outcome marker.
  static List<String> outcomeVocabulary(List<String> dimensions) => <String>[
    ...dimensions,
    noLiveOutcome,
  ];

  /// The consent vocabulary derived from the committed 113.3 witness: the
  /// declared consent basis plus the no-participant marker.
  static List<String> consentVocabulary(String consentType) => <String>[
    consentType,
    noParticipantConsent,
  ];

  /// The evidence source registered for a canonical workflow.
  static String sourceFor(String workflow) {
    final index = canonicalWorkflows.indexOf(workflow);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical log, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry registers a reference, claims no live outcome, and
  /// records its request as a request -- never a commitment.
  static const Sprint118FeedbackAdoptionLog
  canonicalLog = Sprint118FeedbackAdoptionLog(
    releaseState: delayedReleaseState,
    entries: <Sprint118FeedbackEntry>[
      Sprint118FeedbackEntry(
        workflow: 'writer',
        evidenceId: 'FEEDBACK-WRITER-REF',
        source: 'docs/planning/v1.2/sprint_113_writer_workflow_validation.json',
        consent: noParticipantConsent,
        outcome: noLiveOutcome,
        friction: noFrictionRecorded,
        request: 'requested:community_export',
        limitations: <String>[
          'no_live_telemetry',
          'request_is_not_a_commitment',
        ],
      ),
      Sprint118FeedbackEntry(
        workflow: 'lore',
        evidenceId: 'FEEDBACK-LORE-REF',
        source:
            'docs/planning/v1.2/sprint_113_lore_encyclopedia_workflow_validation.json',
        consent: noParticipantConsent,
        outcome: noLiveOutcome,
        friction: noFrictionRecorded,
        request: noRequestRecorded,
        limitations: <String>['no_live_telemetry'],
      ),
      Sprint118FeedbackEntry(
        workflow: 'simulation',
        evidenceId: 'FEEDBACK-SIMULATION-REF',
        source:
            'docs/planning/v1.2/sprint_113_world_simulation_workflow_validation.json',
        consent: noParticipantConsent,
        outcome: noLiveOutcome,
        friction: noFrictionRecorded,
        request: noRequestRecorded,
        limitations: <String>['no_live_telemetry'],
      ),
      Sprint118FeedbackEntry(
        workflow: 'sharing',
        evidenceId: 'FEEDBACK-SHARING-REF',
        source:
            'docs/planning/v1.2/sprint_112_end_to_end_beta_reader_workflow.json',
        consent: noParticipantConsent,
        outcome: noLiveOutcome,
        friction: noFrictionRecorded,
        request: 'requested:reader_network_share',
        limitations: <String>[
          'no_live_telemetry',
          'request_is_not_a_commitment',
        ],
      ),
      Sprint118FeedbackEntry(
        workflow: 'publishing',
        evidenceId: 'FEEDBACK-PUBLISHING-REF',
        source:
            'docs/planning/v1.2/sprint_112_end_to_end_publishing_workflow.json',
        consent: noParticipantConsent,
        outcome: noLiveOutcome,
        friction: noFrictionRecorded,
        request: noRequestRecorded,
        limitations: <String>['no_live_telemetry'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, 114.23 workflow witness,
/// and 113.3 consent witness. Never invents: an unreadable witness yields
/// `null`, which the gate reports as blocked rather than as a pass.
class Sprint118FeedbackAdoptionLoader {
  const Sprint118FeedbackAdoptionLoader();

  Sprint118FeedbackAdoptionAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118FeedbackAdoptionContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118FeedbackAdoptionContract.charterManifestPath,
    );
    if (charter == null) return null;
    final workflow = _readJsonObject(
      Sprint118FeedbackAdoptionContract.workflowManifestPath,
    );
    if (workflow == null) return null;
    final consent = _readJsonObject(
      Sprint118FeedbackAdoptionContract.consentManifestPath,
    );
    if (consent == null) return null;

    final readable = <String>[
      for (final source in Sprint118FeedbackAdoptionContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    final consentContract = consent['consent_contract'];

    return Sprint118FeedbackAdoptionAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      liveAdoptionExecuted:
          _text(workflow['end_user_validation']) !=
          Sprint118FeedbackAdoptionContract.deferredMarker,
      workflows: _stringList(workflow['workflows']),
      outcomes: _stringList(workflow['dimensions']),
      consentType: consentContract is Map
          ? _text(consentContract['consent_type'])
          : '',
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
}

class Sprint118FeedbackAdoptionGate {
  const Sprint118FeedbackAdoptionGate();

  /// Evaluate the canonical log against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118FeedbackAdoptionReport evaluate() => evaluateWith(
    const Sprint118FeedbackAdoptionLoader().loadAnchor(),
    Sprint118FeedbackAdoptionContract.canonicalLog,
  );

  Sprint118FeedbackAdoptionReport evaluateWith(
    Sprint118FeedbackAdoptionAnchor? anchor,
    Sprint118FeedbackAdoptionLog log,
  ) {
    if (anchor == null) {
      return Sprint118FeedbackAdoptionReport(
        state: Sprint118FeedbackLogState.blocked,
        verdict: 'SPRINT_118_FEEDBACK_LOG_EVIDENCE_UNREADABLE',
        releaseState: log.releaseState,
        missingFields: List<String>.from(
          Sprint118FeedbackAdoptionContract.requiredFields,
        ),
        blockers: const <String>['committed_feedback_log_evidence_unreadable'],
        openItems: const <String>['committed_feedback_log_evidence_unreadable'],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A log
    // written against an unfrozen baseline describes feedback nobody measured.
    if (anchor.baselineState !=
            Sprint118FeedbackAdoptionContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118FeedbackAdoptionContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be a genuine complete charter.
    if (anchor.charterState !=
            Sprint118FeedbackAdoptionContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118FeedbackAdoptionContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The release state must agree with the baseline anchor.
    if (anchor.releaseState != log.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'log=${log.releaseState}',
      );
    }

    // (4) On the delayed path no live adoption may be claimed.
    final delayed =
        log.releaseState ==
        Sprint118FeedbackAdoptionContract.delayedReleaseState;
    if (delayed && anchor.liveAdoptionExecuted) {
      violations.add('live_adoption_claimed_executed_without_release');
    }

    // (5) The witness vocabularies must actually be present, so the log has
    // something to derive its outcome and consent vocabularies from.
    if (anchor.workflows.isEmpty) {
      openItems.add('upstream_workflow_vocabulary_missing');
    }
    if (anchor.outcomes.isEmpty) {
      openItems.add('upstream_outcome_vocabulary_missing');
    }
    if (anchor.consentType.isEmpty) {
      openItems.add('upstream_consent_vocabulary_missing');
    }

    // (6) Every canonical workflow must be present exactly once, and each entry
    // must carry all eight required fields non-blank.
    final declared = <String, int>{};
    for (final entry in log.entries) {
      declared[entry.workflow] = (declared[entry.workflow] ?? 0) + 1;
    }
    final outcomeVocabulary =
        Sprint118FeedbackAdoptionContract.outcomeVocabulary(anchor.outcomes);
    final consentVocabulary =
        Sprint118FeedbackAdoptionContract.consentVocabulary(anchor.consentType);
    for (final entry in log.entries) {
      final workflow = entry.workflow;
      if (!Sprint118FeedbackAdoptionContract.canonicalWorkflows.contains(
        workflow,
      )) {
        violations.add('workflow_unknown:$workflow');
      }
      for (final field in Sprint118FeedbackAdoptionContract.requiredFields) {
        final value = entry.fields[field] ?? '';
        if (value.trim().isEmpty) {
          violations.add('entry_blank_$field:$workflow');
        }
      }
      if (!consentVocabulary.contains(entry.consent)) {
        violations.add('entry_unknown_consent:$workflow:${entry.consent}');
      }
      if (delayed &&
          anchor.consentType.isNotEmpty &&
          entry.consent == anchor.consentType) {
        violations.add(
          'participant_consent_claimed_without_participant:$workflow:'
          '${entry.consent}',
        );
      }
      if (!outcomeVocabulary.contains(entry.outcome)) {
        violations.add('entry_unknown_outcome:$workflow:${entry.outcome}');
      }
      if (delayed &&
          entry.outcome != Sprint118FeedbackAdoptionContract.noLiveOutcome) {
        violations.add(
          'workflow_claims_live_outcome_without_release:$workflow:'
          '${entry.outcome}',
        );
      }
      // A request is never a commitment.
      if (entry.requestIsCommitment) {
        violations.add('request_treated_as_commitment:$workflow');
      }
      final request = entry.request;
      if (request != Sprint118FeedbackAdoptionContract.noRequestRecorded &&
          !request.startsWith(
            Sprint118FeedbackAdoptionContract.requestPrefix,
          )) {
        violations.add('request_malformed:$workflow:$request');
      }
      if (!anchor.readableSources.contains(entry.source)) {
        violations.add('entry_unreadable_source:$workflow:${entry.source}');
      }
    }
    for (final workflow in declared.keys) {
      if (declared[workflow]! > 1) {
        violations.add('workflow_duplicate:$workflow');
      }
    }
    for (final workflow
        in Sprint118FeedbackAdoptionContract.canonicalWorkflows) {
      if (!declared.containsKey(workflow)) {
        violations.add('workflow_missing:$workflow');
      }
    }

    // (7) Every committed evidence source must be readable.
    for (final source in Sprint118FeedbackAdoptionContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final workflows = log.workflows;

    if (violations.isNotEmpty) {
      return Sprint118FeedbackAdoptionReport(
        state: Sprint118FeedbackLogState.fail,
        verdict: 'SPRINT_118_FEEDBACK_LOG_VIOLATION',
        releaseState: log.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredWorkflows: workflows,
        entryCount: log.entries.length,
        outcomeVocabulary: outcomeVocabulary,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118FeedbackAdoptionReport(
        state: Sprint118FeedbackLogState.blocked,
        verdict: 'SPRINT_118_FEEDBACK_LOG_BLOCKED_UPSTREAM',
        releaseState: log.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredWorkflows: workflows,
        entryCount: log.entries.length,
        outcomeVocabulary: outcomeVocabulary,
      );
    }
    return Sprint118FeedbackAdoptionReport(
      state: Sprint118FeedbackLogState.pass,
      verdict: 'FEEDBACK_ADOPTION_EVIDENCE_LOG_VERIFIED_LOCAL',
      releaseState: log.releaseState,
      openItems: allOpen,
      declaredWorkflows: workflows,
      entryCount: log.entries.length,
      outcomeVocabulary: outcomeVocabulary,
    );
  }
}
