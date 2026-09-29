library;

import 'dart:convert';
import 'dart:io';

/// Fail-closed charter contract for Sprint 117.2.
///
/// Canonical step 117.2 asks for exactly one deliverable: a beta validation
/// charter that fixes the `window`, `questions`, `connector_subset`, `evidence`,
/// `owners`, `stop_conditions`, and `ga_criteria` before any beta cohort is
/// approached. This gate makes that charter checkable instead of prose.
///
/// The charter never invents a beta programme. Every field is either derived
/// from committed Sprint 116 evidence — the 116.50 staged rollout plan, the
/// 116.51 acceptance gate, and the 117.1 entry gate — or declared here against
/// source manifests that must exist on disk. A question nobody can evidence, a
/// rollout stage no phase covers, a metric no stop condition watches, or a GA
/// gate the canonical `release_rules` requires but the charter forgot, all fail
/// closed. Live beta execution, participant recruitment, and real consent stay
/// `DEFERRED-EXTERNAL`.
enum Sprint117CharterState { pass, fail, blocked }

class Sprint117CharterPhase {
  const Sprint117CharterPhase({
    required this.phaseId,
    required this.stageId,
    required this.startEpochMs,
    required this.endEpochMs,
    required this.exitCriterion,
  });

  final String phaseId;
  final String stageId;
  final int startEpochMs;
  final int endEpochMs;
  final String exitCriterion;
}

class Sprint117CharterWindow {
  const Sprint117CharterWindow({
    required this.windowId,
    required this.startEpochMs,
    required this.endEpochMs,
    required this.durationDays,
    required this.phases,
  });

  final String windowId;
  final int startEpochMs;
  final int endEpochMs;
  final int durationDays;
  final List<Sprint117CharterPhase> phases;

  List<String> get coveredStages => <String>[
    for (final phase in phases)
      if (phase.stageId.trim().isNotEmpty) phase.stageId.trim(),
  ];
}

class Sprint117CharterQuestion {
  const Sprint117CharterQuestion({
    required this.questionId,
    required this.area,
    required this.step,
    required this.question,
    required this.measurable,
    this.sourceManifests = const <String>[],
  });

  final String questionId;
  final String area;
  final String step;
  final String question;
  final bool measurable;
  final List<String> sourceManifests;
}

class Sprint117CharterSubset {
  const Sprint117CharterSubset({
    required this.exposed,
    required this.hidden,
    required this.rolloutExposed,
  });

  final List<String> exposed;
  final List<String> hidden;
  final List<String> rolloutExposed;
}

class Sprint117CharterEvidencePlan {
  const Sprint117CharterEvidencePlan({
    required this.questionId,
    required this.requiredArtifacts,
    required this.sourceManifests,
  });

  final String questionId;
  final List<String> requiredArtifacts;
  final List<String> sourceManifests;
}

class Sprint117CharterOwner {
  const Sprint117CharterOwner({
    required this.ownerId,
    required this.role,
    required this.scopes,
  });

  final String ownerId;
  final String role;
  final List<String> scopes;
}

class Sprint117CharterStopCondition {
  const Sprint117CharterStopCondition({
    required this.stopId,
    required this.stageId,
    required this.metricId,
    required this.operator,
    required this.threshold,
    required this.windowMinutes,
    required this.action,
    required this.killSwitchRef,
  });

  final String stopId;
  final String stageId;
  final String metricId;
  final String operator;
  final double threshold;
  final int windowMinutes;
  final String action;
  final String killSwitchRef;
}

class Sprint117CharterGaCriterion {
  const Sprint117CharterGaCriterion({
    required this.criterionId,
    required this.gate,
    required this.step,
    required this.criterion,
    required this.evidenceRequired,
  });

  final String criterionId;
  final String gate;
  final String step;
  final String criterion;
  final bool evidenceRequired;
}

/// The 117.1 verdict this charter is allowed to build on. A charter written
/// against a blocked entry gate describes a beta that may not start.
class Sprint117CharterAnchor {
  const Sprint117CharterAnchor({
    required this.entryVerdict,
    required this.betaVersion,
    required this.pubspecVersion,
    required this.releaseCut,
    required this.exposedSubset,
    required this.stages,
    required this.metrics,
    required this.killSwitchConnectors,
    required this.openItemIds,
  });

  final String entryVerdict;
  final String betaVersion;
  final String pubspecVersion;
  final bool releaseCut;
  final List<String> exposedSubset;
  final List<String> stages;
  final List<String> metrics;
  final List<String> killSwitchConnectors;
  final List<String> openItemIds;
}

class Sprint117CharterInput {
  const Sprint117CharterInput({
    this.window,
    this.questions,
    this.connectorSubset,
    this.evidence,
    this.owners,
    this.stopConditions,
    this.gaCriteria,
    this.anchor,
    this.carriedOpenItems = const <String>[],
  });

  final Sprint117CharterWindow? window;
  final List<Sprint117CharterQuestion>? questions;
  final Sprint117CharterSubset? connectorSubset;
  final List<Sprint117CharterEvidencePlan>? evidence;
  final List<Sprint117CharterOwner>? owners;
  final List<Sprint117CharterStopCondition>? stopConditions;
  final List<Sprint117CharterGaCriterion>? gaCriteria;
  final Sprint117CharterAnchor? anchor;
  final List<String> carriedOpenItems;
}

class Sprint117CharterReport {
  Sprint117CharterReport({
    required this.state,
    required this.verdict,
    required List<String> missingFields,
    required List<String> violations,
    required this.window,
    required List<Sprint117CharterQuestion> questions,
    required this.connectorSubset,
    required List<Sprint117CharterEvidencePlan> evidencePlans,
    required List<Sprint117CharterOwner> owners,
    required List<Sprint117CharterStopCondition> stopConditions,
    required List<Sprint117CharterGaCriterion> gaCriteria,
    required this.anchor,
    required List<String> carriedOpenItems,
    required Map<String, int> fieldCoverage,
    required List<String> ownedScopes,
    required List<String> openItems,
    required List<String> limitations,
  }) : missingFields = List<String>.unmodifiable(missingFields),
       violations = List<String>.unmodifiable(violations),
       questions = List<Sprint117CharterQuestion>.unmodifiable(questions),
       evidencePlans = List<Sprint117CharterEvidencePlan>.unmodifiable(
         evidencePlans,
       ),
       owners = List<Sprint117CharterOwner>.unmodifiable(owners),
       stopConditions = List<Sprint117CharterStopCondition>.unmodifiable(
         stopConditions,
       ),
       gaCriteria = List<Sprint117CharterGaCriterion>.unmodifiable(gaCriteria),
       carriedOpenItems = List<String>.unmodifiable(carriedOpenItems),
       fieldCoverage = Map<String, int>.unmodifiable(fieldCoverage),
       ownedScopes = List<String>.unmodifiable(ownedScopes),
       openItems = List<String>.unmodifiable(openItems),
       limitations = List<String>.unmodifiable(limitations);

  final Sprint117CharterState state;
  final String verdict;
  final List<String> missingFields;
  final List<String> violations;
  final Sprint117CharterWindow? window;
  final List<Sprint117CharterQuestion> questions;
  final Sprint117CharterSubset? connectorSubset;
  final List<Sprint117CharterEvidencePlan> evidencePlans;
  final List<Sprint117CharterOwner> owners;
  final List<Sprint117CharterStopCondition> stopConditions;
  final List<Sprint117CharterGaCriterion> gaCriteria;
  final Sprint117CharterAnchor? anchor;
  final List<String> carriedOpenItems;
  final Map<String, int> fieldCoverage;
  final List<String> ownedScopes;
  final List<String> openItems;
  final List<String> limitations;

  String get externalGates => Sprint117CharterContract.externalGates;

  bool get liveBetaExecuted => false;

  Map<String, Object?> toJson() => <String, Object?>{
    'state': state.name,
    'verdict': verdict,
    'missing_fields': List<String>.from(missingFields),
    'violations': List<String>.from(violations),
    'window': window == null
        ? null
        : <String, Object?>{
            'window_id': window!.windowId,
            'start_epoch_ms': window!.startEpochMs,
            'end_epoch_ms': window!.endEpochMs,
            'duration_days': window!.durationDays,
            'phases': <Map<String, Object?>>[
              for (final phase in window!.phases)
                <String, Object?>{
                  'phase_id': phase.phaseId,
                  'stage_id': phase.stageId,
                  'start_epoch_ms': phase.startEpochMs,
                  'end_epoch_ms': phase.endEpochMs,
                  'exit_criterion': phase.exitCriterion,
                },
            ],
          },
    'questions': <Map<String, Object?>>[
      for (final question in questions)
        <String, Object?>{
          'question_id': question.questionId,
          'area': question.area,
          'step': question.step,
          'question': question.question,
          'measurable': question.measurable,
          'source_manifests': List<String>.from(question.sourceManifests),
        },
    ],
    'connector_subset': connectorSubset == null
        ? null
        : <String, Object?>{
            'exposed': List<String>.from(connectorSubset!.exposed),
            'hidden': List<String>.from(connectorSubset!.hidden),
            'rollout_exposed': List<String>.from(
              connectorSubset!.rolloutExposed,
            ),
          },
    'evidence': <Map<String, Object?>>[
      for (final plan in evidencePlans)
        <String, Object?>{
          'question_id': plan.questionId,
          'required_artifacts': List<String>.from(plan.requiredArtifacts),
          'source_manifests': List<String>.from(plan.sourceManifests),
        },
    ],
    'owners': <Map<String, Object?>>[
      for (final owner in owners)
        <String, Object?>{
          'owner_id': owner.ownerId,
          'role': owner.role,
          'scopes': List<String>.from(owner.scopes),
        },
    ],
    'stop_conditions': <Map<String, Object?>>[
      for (final stop in stopConditions)
        <String, Object?>{
          'stop_id': stop.stopId,
          'stage_id': stop.stageId,
          'metric_id': stop.metricId,
          'operator': stop.operator,
          'threshold': stop.threshold,
          'window_minutes': stop.windowMinutes,
          'action': stop.action,
          'kill_switch_ref': stop.killSwitchRef,
        },
    ],
    'ga_criteria': <Map<String, Object?>>[
      for (final criterion in gaCriteria)
        <String, Object?>{
          'criterion_id': criterion.criterionId,
          'gate': criterion.gate,
          'step': criterion.step,
          'criterion': criterion.criterion,
          'evidence_required': criterion.evidenceRequired,
        },
    ],
    'field_coverage': Map<String, int>.from(fieldCoverage),
    'owned_scopes': List<String>.from(ownedScopes),
    'carried_open_items': List<String>.from(carriedOpenItems),
    'external_gates': externalGates,
    'open_items': List<String>.from(openItems),
    'limitations': List<String>.from(limitations),
  };
}

abstract final class Sprint117CharterContract {
  static const String canonicalStep = '117.2';

  /// Milliseconds in one day. Named because `Duration.inMilliseconds` is not
  /// const-evaluable, and the window arithmetic needs the constant.
  static const int dayInMilliseconds = 86400000;

  static const String manifestPath =
      'docs/planning/v1.3/sprint_117_beta_validation_charter.json';
  static const String ledgerPath = 'docs/sprints/sprint-117-beta-validation.md';
  static const String entryManifestPath =
      'docs/planning/v1.3/sprint_117_beta_entry_gate.json';
  static const String rolloutManifestPath =
      'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json';
  static const String acceptanceManifestPath =
      'docs/planning/v1.2/sprint_116_beta_acceptance_gate.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The 117.1 verdict the charter must be built on.
  static const String entryVerdict = 'BETA_ENTRY_LOCAL_READY';

  /// The seven charter fields canonical step 117.2 names, in canonical order.
  static const List<String> requiredFields = <String>[
    'window',
    'questions',
    'connector_subset',
    'evidence',
    'owners',
    'stop_conditions',
    'ga_criteria',
  ];

  static const List<String> knownVerdicts = <String>[
    'CHARTER_COMPLETE_LOCAL',
    'CHARTER_BLOCKED',
    'CHARTER_FAILED',
  ];

  /// Areas a beta validation question may target. Derived from the Sprint 117
  /// workflow steps 117.3-117.36; a question outside them is a wish, not a
  /// validation question.
  static const List<String> knownAreas = <String>[
    'cohort_consent',
    'installation_upgrade',
    'account_migration',
    'identity_workflow',
    'sync_backup_conflict',
    'api_key_workflow',
    'security_center',
    'billing_webhook',
    'provider_icon_brand',
    'accessibility',
    'offline_cached_state',
    'failure_state',
    'quota_accuracy',
    'usage_cost',
    'privacy',
    'provider_resilience',
    'support_incident',
    'staged_rollout',
  ];

  /// GA gates the canonical `release_rules` demand. A charter that omits any of
  /// them promises a GA it has not defined a bar for.
  static const List<String> requiredGaGates = <String>[
    'security',
    'privacy',
    'accessibility',
    'kill_switch',
    'staged_rollout',
    'rollback',
  ];

  /// Scopes a charter owner may be accountable for. An unowned scope blocks the
  /// charter: nobody would notice the gap.
  static const List<String> knownOwnerScopes = <String>[
    'charter',
    'question',
    'stop_condition',
    'ga_criteria',
    'incident',
  ];

  /// Stop actions that actually stop exposure. `page_oncall` alone is a
  /// notification, not a stop: the charter requires a containment action.
  static const List<String> containmentActions = <String>[
    'halt_rollout',
    'rollback_stage',
    'rollback_full',
    'kill_connector',
  ];

  static const List<String> knownOperators = <String>['gt', 'gte', 'lt', 'lte'];

  /// The planned beta window. It is a plan, not a clock: no beta has run, and
  /// `date` is deliberately absent so the charter stays deterministic.
  static const String windowId = 'beta_validation_window';
  static const int plannedWindowStartEpochMs = 1791158400000; // 2026-10-05
  static const List<int> plannedPhaseDays = <int>[7, 14, 21];
  static const int plannedWindowDays = 42;

  /// The questions this beta must answer before GA, each bound to the canonical
  /// step that owns it and to source manifests that must exist on disk.
  static const List<Sprint117CharterQuestion>
  charterQuestions = <Sprint117CharterQuestion>[
    Sprint117CharterQuestion(
      questionId: 'q_cohort_consent',
      area: 'cohort_consent',
      step: '117.3',
      question:
          'Apakah setiap peserta beta terdaftar dengan consent eksplisit, terdokumentasi, dan dapat ditarik?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_installation_upgrade',
      area: 'installation_upgrade',
      step: '117.9',
      question:
          'Apakah instalasi bersih dan upgrade dari build sebelumnya mempertahankan proyek pengguna tanpa kehilangan data?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_113_upgrade_path_validation.json',
        'docs/planning/v1.2/sprint_114_install_update_health.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_account_migration',
      area: 'account_migration',
      step: '117.10',
      question:
          'Apakah konfigurasi akun migrasi utuh tanpa menimpa setelan lokal pengguna?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_114_migration_data_repair_fixes.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_sync_backup_conflict',
      area: 'sync_backup_conflict',
      step: '117.14',
      question:
          'Apakah sinkronisasi, backup, dan resolusi konflik tetap benar ketika dua perangkat menulis proyek yang sama?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_cross_storage_sync_backup_certification.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_security_center',
      area: 'security_center',
      step: '117.20',
      question:
          'Apakah Security Center melaporkan status connector yang sama dengan kenyataan dan tidak pernah meloloskan secret ke log?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_security_certification_gate.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_billing_webhook',
      area: 'billing_webhook',
      step: '117.34',
      question:
          'Apakah entitlement, webhook, dan settlement konsisten pada semua provider pembayaran yang dibiakkan?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_accessibility',
      area: 'accessibility',
      step: '117.25',
      question:
          'Apakah seluruh alur beta dapat diselesaikan dengan keyboard dan reader layar pada kontras yang memenuhi ambang?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_brand_visual_accessibility_gate.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_offline_cached_state',
      area: 'offline_cached_state',
      step: '117.27',
      question:
          'Apakah state offline dan cache tetap jujur dan dapat dipulihkan tanpa kehilangan metadata pengguna?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_offline_cached_metadata_certification.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_failure_state',
      area: 'failure_state',
      step: '117.28',
      question:
          'Apakah kegagalan provider ditunjukkan sebagai keadaan nyata, bukan kondisi sukses yang menipu?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_provider_error_state_certification.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_quota_accuracy',
      area: 'quota_accuracy',
      step: '117.29',
      question:
          'Apakah kuota yang ditampilkan cocok dengan pemakaian yang dilaporkan lintas provider?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_quota_usage_cross_provider_contract.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_usage_cost',
      area: 'usage_cost',
      step: '117.30',
      question:
          'Apakah biaya pemakaian yang dilaporkan cocok dengan tagihan provider untuk periode yang sama?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_privacy',
      area: 'privacy',
      step: '117.33',
      question:
          'Apakah data yang meninggalkan perangkat hanya data yang tercantum dalam consent dan=data_boundaries?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_privacy_compliance_gate.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_provider_resilience',
      area: 'provider_resilience',
      step: '117.36',
      question:
          'Apakah retry, backoff, dan circuit breaker mencegah kegagalan provider menjadi kehilangan data pengguna?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
      ],
    ),
    Sprint117CharterQuestion(
      questionId: 'q_support_incident',
      area: 'support_incident',
      step: '117.6',
      question:
          'Apakah setiap insiden beta mendapat owner, klasifikasi, dan jalur eskalasi dalam SLA yang tertulis?',
      measurable: true,
      sourceManifests: <String>[
        'docs/planning/v1.2/sprint_116_beta_cohort_consent_plan.json',
      ],
    ),
  ];

  /// GA criteria the charter must carry, one per required gate, each bound to
  /// the canonical step that produces its evidence.
  static const List<Sprint117CharterGaCriterion>
  gaCriteria = <Sprint117CharterGaCriterion>[
    Sprint117CharterGaCriterion(
      criterionId: 'ga_security',
      gate: 'security',
      step: '117.32',
      criterion:
          'Security assessment selesai tanpa temuan Sev-1 yang belum memiliki owner dan rencana mitigasi.',
      evidenceRequired: true,
    ),
    Sprint117CharterGaCriterion(
      criterionId: 'ga_privacy',
      gate: 'privacy',
      step: '117.33',
      criterion:
          'Privacy assessment selesai dan seluruh data yang keluar perangkat terpetakan ke consent yang berlaku.',
      evidenceRequired: true,
    ),
    Sprint117CharterGaCriterion(
      criterionId: 'ga_accessibility',
      gate: 'accessibility',
      step: '117.25',
      criterion:
          'Accessibility validation hijau pada seluruh alur beta yang diuji, dengan bukti pengujian tersimpan.',
      evidenceRequired: true,
    ),
    Sprint117CharterGaCriterion(
      criterionId: 'ga_kill_switch',
      gate: 'kill_switch',
      step: '117.8',
      criterion:
          'Drill kill switch provider dijalankan terhadap sistem nyata dan terbukti menghentikan connector yang sedang diekspos.',
      evidenceRequired: true,
    ),
    Sprint117CharterGaCriterion(
      criterionId: 'ga_staged_rollout',
      gate: 'staged_rollout',
      step: '117.44',
      criterion:
          'Staged rollout mencapai tahap akhir tanpa stop condition yang terpicu dan tanpa Sev-1 terbuka.',
      evidenceRequired: true,
    ),
    Sprint117CharterGaCriterion(
      criterionId: 'ga_rollback',
      gate: 'rollback',
      step: '117.43',
      criterion:
          'Rollback terverifikasi terhadap artefak beta yang benar-benar dipublikasikan, bukan terhadap build lokal.',
      evidenceRequired: true,
    ),
  ];
}

class Sprint117CharterLoader {
  const Sprint117CharterLoader();

  Sprint117CharterInput load() => Sprint117CharterInput(
    window: _loadWindow(),
    questions: Sprint117CharterContract.charterQuestions,
    connectorSubset: _loadSubset(),
    evidence: _loadEvidence(),
    owners: _loadOwners(),
    stopConditions: _loadStopConditions(),
    gaCriteria: Sprint117CharterContract.gaCriteria,
    anchor: _loadAnchor(),
    carriedOpenItems: _loadOpenItems(),
  );

  /// One phase per 116.50 rollout stage, in stage sequence, so the window is
  /// derived from the committed rollout plan instead of a free-form calendar.
  Sprint117CharterWindow? _loadWindow() {
    final stages = _readList(
      Sprint117CharterContract.rolloutManifestPath,
      'stages',
    );
    if (stages == null || stages.isEmpty) return null;

    final ordered = <Map<String, dynamic>>[];
    for (final raw in stages) {
      if (raw is Map<String, dynamic>) ordered.add(raw);
    }
    if (ordered.isEmpty) return null;
    ordered.sort((a, b) {
      final left = a['sequence'] is int ? a['sequence']! as int : 0;
      final right = b['sequence'] is int ? b['sequence']! as int : 0;
      return left.compareTo(right);
    });

    const dayMs = Sprint117CharterContract.dayInMilliseconds;
    final phases = <Sprint117CharterPhase>[];
    var cursor = Sprint117CharterContract.plannedWindowStartEpochMs;
    for (var index = 0; index < ordered.length; index++) {
      final stage = ordered[index];
      final stageId = _text(stage['stage_id']);
      if (stageId.isEmpty) return null;
      final int days = index < Sprint117CharterContract.plannedPhaseDays.length
          ? Sprint117CharterContract.plannedPhaseDays[index]
          : Sprint117CharterContract.plannedPhaseDays.last;
      final int start = cursor;
      final int end = start + days * dayMs;
      final exitCriteria = _stringList(stage['exit_criteria']);
      phases.add(
        Sprint117CharterPhase(
          phaseId: 'phase_${stageId.replaceFirst('stage_', '')}',
          stageId: stageId,
          startEpochMs: start,
          endEpochMs: end,
          exitCriterion: exitCriteria.isEmpty ? '' : exitCriteria.first,
        ),
      );
      cursor = end;
    }

    return Sprint117CharterWindow(
      windowId: Sprint117CharterContract.windowId,
      startEpochMs: Sprint117CharterContract.plannedWindowStartEpochMs,
      endEpochMs: cursor,
      durationDays: Sprint117CharterContract.plannedWindowDays,
      phases: phases,
    );
  }

  Sprint117CharterSubset? _loadSubset() {
    final entry = _readJsonObject(Sprint117CharterContract.entryManifestPath);
    if (entry == null) return null;
    final exposed = _stringList(entry['exposed_beta_subset']);
    if (exposed.isEmpty) return null;
    final hidden = _stringList(entry['hidden_from_beta']);
    final rollout = <String>{};
    final stages = _readList(
      Sprint117CharterContract.rolloutManifestPath,
      'stages',
    );
    if (stages != null) {
      for (final raw in stages) {
        if (raw is! Map<String, dynamic>) continue;
        for (final connector in _stringList(raw['exposed_connectors'])) {
          rollout.add(connector);
        }
      }
    }
    return Sprint117CharterSubset(
      exposed: exposed,
      hidden: hidden,
      rolloutExposed: rollout.toList(growable: false),
    );
  }

  List<Sprint117CharterEvidencePlan>
  _loadEvidence() => <Sprint117CharterEvidencePlan>[
    for (final question in Sprint117CharterContract.charterQuestions)
      Sprint117CharterEvidencePlan(
        questionId: question.questionId,
        // The artifact a future run must produce; it does not exist yet, and
        // that is honest: the beta has not run.
        requiredArtifacts: <String>[
          'docs/evidence/sprint_117-beta-${question.questionId.replaceFirst('q_', '')}.json',
        ],
        sourceManifests: question.sourceManifests,
      ),
  ];

  List<Sprint117CharterOwner> _loadOwners() => <Sprint117CharterOwner>[
    const Sprint117CharterOwner(
      ownerId: 'release-owner',
      role: 'release_owner',
      scopes: <String>['charter', 'stop_condition', 'ga_criteria'],
    ),
    const Sprint117CharterOwner(
      ownerId: 'support-owner',
      role: 'support_owner',
      scopes: <String>['question', 'incident'],
    ),
  ];

  List<Sprint117CharterStopCondition> _loadStopConditions() {
    final stops = _readList(
      Sprint117CharterContract.rolloutManifestPath,
      'stop_conditions',
    );
    if (stops == null) return const <Sprint117CharterStopCondition>[];
    final killByStage = _killSwitchByConnector();
    final result = <Sprint117CharterStopCondition>[];
    for (final raw in stops) {
      if (raw is! Map<String, dynamic>) continue;
      final stopId = _text(raw['stop_id']);
      final stageId = _text(raw['stage_id']);
      if (stopId.isEmpty || stageId.isEmpty) continue;
      final action = _text(raw['action']);
      final connector = _firstConnectorForStage(stageId, killByStage);
      result.add(
        Sprint117CharterStopCondition(
          stopId: 'charter_$stopId',
          stageId: stageId,
          metricId: _text(raw['metric_id']),
          operator: _text(raw['operator']),
          threshold: _double(raw['threshold']) ?? 0,
          windowMinutes: _int(raw['window_minutes']) ?? 0,
          action: action,
          killSwitchRef: connector,
        ),
      );
    }
    return result;
  }

  /// `connector_id` -> `kill_id`, so a stop condition can name the switch that
  /// actually contains the incident instead of a decorative reference.
  Map<String, String> _killSwitchByConnector() {
    final map = <String, String>{};
    final kills = _readList(
      Sprint117CharterContract.rolloutManifestPath,
      'provider_kill_switches',
    );
    if (kills == null) return map;
    for (final raw in kills) {
      if (raw is! Map<String, dynamic>) continue;
      final connector = _text(raw['connector_id']);
      final killId = _text(raw['kill_id']);
      if (connector.isNotEmpty && killId.isNotEmpty) map[connector] = killId;
    }
    return map;
  }

  String _firstConnectorForStage(
    String stageId,
    Map<String, String> killByStage,
  ) {
    final stages = _readList(
      Sprint117CharterContract.rolloutManifestPath,
      'stages',
    );
    if (stages == null) return '';
    for (final raw in stages) {
      if (raw is! Map<String, dynamic>) continue;
      if (_text(raw['stage_id']) != stageId) continue;
      for (final connector in _stringList(raw['exposed_connectors'])) {
        final kill = killByStage[connector];
        if (kill != null) return kill;
      }
    }
    return '';
  }

  Sprint117CharterAnchor? _loadAnchor() {
    final entry = _readJsonObject(Sprint117CharterContract.entryManifestPath);
    if (entry == null) return null;
    final stages = <String>{};
    final metrics = <String>{};
    final killConnectors = <String>{};
    final rawStages = _readList(
      Sprint117CharterContract.rolloutManifestPath,
      'stages',
    );
    if (rawStages != null) {
      for (final raw in rawStages) {
        if (raw is! Map<String, dynamic>) continue;
        final id = _text(raw['stage_id']);
        if (id.isNotEmpty) stages.add(id);
      }
    }
    final rawMetrics = _readList(
      Sprint117CharterContract.rolloutManifestPath,
      'health_metrics',
    );
    if (rawMetrics != null) {
      for (final raw in rawMetrics) {
        if (raw is! Map<String, dynamic>) continue;
        final id = _text(raw['metric_id']);
        if (id.isNotEmpty) metrics.add(id);
      }
    }
    final rawKills = _readList(
      Sprint117CharterContract.rolloutManifestPath,
      'provider_kill_switches',
    );
    if (rawKills != null) {
      for (final raw in rawKills) {
        if (raw is! Map<String, dynamic>) continue;
        final id = _text(raw['connector_id']);
        if (id.isNotEmpty) killConnectors.add(id);
      }
    }

    return Sprint117CharterAnchor(
      entryVerdict: _text(entry['verdict']),
      betaVersion: _text(entry['beta_version']),
      pubspecVersion: _text(entry['pubspec_version']),
      releaseCut: entry['release_cut'] == true,
      exposedSubset: _stringList(entry['exposed_beta_subset']),
      stages: stages.toList(growable: false),
      metrics: metrics.toList(growable: false),
      killSwitchConnectors: killConnectors.toList(growable: false),
      openItemIds: _openItemIds(_loadOpenItems()),
    );
  }

  List<String> _loadOpenItems() {
    final acceptance = _readJsonObject(
      Sprint117CharterContract.acceptanceManifestPath,
    );
    if (acceptance == null) return const <String>[];
    return _stringList(acceptance['open_items']);
  }

  List<String> _openItemIds(List<String> items) => <String>[
    for (final item in items)
      item.contains(':') ? item.split(':').first.trim() : item.trim(),
  ];

  List<dynamic>? _readList(String path, String key) {
    final manifest = _readJsonObject(path);
    if (manifest == null) return null;
    final value = manifest[key];
    return value is List ? value : null;
  }

  Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    final items = <String>[];
    for (final raw in value) {
      final id = _text(raw);
      if (id.isNotEmpty && !items.contains(id)) items.add(id);
    }
    return items;
  }

  int? _int(Object? value) => value is int ? value : null;

  double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  String _text(Object? value) => value == null ? '' : value.toString().trim();
}

class Sprint117CharterGate {
  Sprint117CharterReport evaluate() =>
      evaluateWith(const Sprint117CharterLoader().load());

  Sprint117CharterReport evaluateWith(Sprint117CharterInput input) {
    final missing = <String>{};
    final violations = <String>[];

    final anchor = input.anchor;
    if (anchor == null) {
      missing.add('entry_anchor');
    } else if (anchor.entryVerdict != Sprint117CharterContract.entryVerdict) {
      // A charter written on top of a blocked or failed entry gate describes a
      // beta that may not start; that is missing evidence, not a contradiction.
      missing.add('entry_anchor');
    }

    // --- window -----------------------------------------------------------
    final anchorStages = anchor?.stages ?? const <String>[];
    final anchorMetrics = anchor?.metrics ?? const <String>[];
    final window = input.window;
    if (window == null) {
      missing.add('window');
    } else {
      if (window.endEpochMs <= window.startEpochMs) {
        violations.add(
          'window_order:${window.startEpochMs}:${window.endEpochMs}',
        );
      }
      if (window.durationDays <= 0) {
        violations.add('window_duration');
      }
      if (window.phases.isEmpty) {
        missing.add('window');
      } else {
        const dayMs = Sprint117CharterContract.dayInMilliseconds;
        final spanDays = (window.endEpochMs - window.startEpochMs) ~/ dayMs;
        if (spanDays != window.durationDays) {
          violations.add(
            'window_duration_mismatch:$spanDays:${window.durationDays}',
          );
        }
        final covered = window.coveredStages.toSet();
        for (final stage in anchorStages) {
          if (!covered.contains(stage)) {
            violations.add('window_stage_uncovered:$stage');
          }
        }
        for (final phase in window.phases) {
          if (phase.stageId.trim().isEmpty) {
            violations.add('window_phase_stage_blank:${phase.phaseId}');
            continue;
          }
          if (anchorStages.isNotEmpty &&
              !anchorStages.contains(phase.stageId)) {
            violations.add('window_stage_unknown:${phase.stageId}');
          }
          if (phase.endEpochMs <= phase.startEpochMs) {
            violations.add('window_phase_order:${phase.phaseId}');
          }
          if (phase.exitCriterion.trim().isEmpty) {
            violations.add('window_exit_criterion:${phase.phaseId}');
          }
        }
      }
    }

    // --- questions --------------------------------------------------------
    final questions = input.questions;
    final questionIds = <String>{};
    if (questions == null || questions.isEmpty) {
      missing.add('questions');
    } else {
      for (final question in questions) {
        final id = question.questionId.trim();
        if (id.isEmpty) {
          violations.add('question_id_blank');
          continue;
        }
        if (!questionIds.add(id)) {
          violations.add('question_duplicate:$id');
          continue;
        }
        if (question.question.trim().isEmpty) {
          violations.add('question_text:$id');
        }
        if (!Sprint117CharterContract.knownAreas.contains(question.area)) {
          violations.add('question_area:$id:${question.area}');
        }
        if (!question.step.startsWith('117.')) {
          violations.add('question_step:$id:${question.step}');
        }
        if (!question.measurable) {
          violations.add('question_measurable:$id');
        }
      }
    }

    // --- connector_subset --------------------------------------------------
    final subset = input.connectorSubset;
    if (subset == null || subset.exposed.isEmpty) {
      missing.add('connector_subset');
    } else if (anchor != null) {
      final declared = <String>{};
      for (final provider in subset.exposed) {
        if (provider.trim().isEmpty) {
          violations.add('subset_provider_blank');
          continue;
        }
        declared.add(provider);
        if (subset.hidden.contains(provider)) {
          violations.add('subset_uncertified:$provider');
        }
        if (!anchor.exposedSubset.contains(provider)) {
          violations.add('subset_drift:$provider');
        }
      }
      for (final provider in anchor.exposedSubset) {
        if (!declared.contains(provider)) {
          violations.add('subset_drift:$provider');
        }
      }
      // Every connector the charter says the rollout will expose must already
      // have a recorded kill switch, otherwise the charter promises exposure it
      // cannot contain.
      for (final connector in subset.rolloutExposed) {
        if (connector.trim().isEmpty) {
          violations.add('subset_rollout_connector_blank');
          continue;
        }
        if (anchor.killSwitchConnectors.isNotEmpty &&
            !anchor.killSwitchConnectors.contains(connector)) {
          violations.add('subset_rollout_gap:$connector');
        }
      }
    }

    // --- evidence ----------------------------------------------------------
    final evidence = input.evidence;
    final evidenceIds = <String>{};
    if (evidence == null || evidence.isEmpty) {
      missing.add('evidence');
    } else {
      for (final plan in evidence) {
        final id = plan.questionId.trim();
        if (id.isEmpty) {
          violations.add('evidence_question_blank');
          continue;
        }
        if (!evidenceIds.add(id)) {
          violations.add('evidence_duplicate:$id');
        }
        if (!questionIds.contains(id)) {
          violations.add('evidence_orphan:$id');
        }
        if (plan.requiredArtifacts.isEmpty) {
          violations.add('evidence_artifact:$id');
        }
        if (plan.sourceManifests.isEmpty) {
          violations.add('evidence_source:$id');
        }
      }
      for (final id in questionIds) {
        if (!evidenceIds.contains(id)) {
          violations.add('evidence_uncovered:$id');
        }
      }
    }

    // --- owners ------------------------------------------------------------
    final owners = input.owners;
    final ownedScopes = <String>{};
    if (owners == null || owners.isEmpty) {
      missing.add('owners');
    } else {
      final ownerIds = <String>{};
      for (final owner in owners) {
        final id = owner.ownerId.trim();
        if (id.isEmpty) {
          violations.add('owner_id_blank');
          continue;
        }
        if (!ownerIds.add(id)) {
          violations.add('owner_duplicate:$id');
          continue;
        }
        if (owner.role.trim().isEmpty) {
          violations.add('owner_role_blank:$id');
        }
        for (final scope in owner.scopes) {
          if (!Sprint117CharterContract.knownOwnerScopes.contains(scope)) {
            violations.add('owner_scope:$id:$scope');
            continue;
          }
          ownedScopes.add(scope);
        }
      }
      for (final scope in Sprint117CharterContract.knownOwnerScopes) {
        if (!ownedScopes.contains(scope)) {
          missing.add('owners');
        }
      }
    }

    // --- stop_conditions ---------------------------------------------------
    final stops = input.stopConditions;
    if (stops == null || stops.isEmpty) {
      missing.add('stop_conditions');
    } else {
      final stopIds = <String>{};
      final coveredStages = <String>{};
      // A stop condition whose action only pages someone is triage, not
      // containment. It is legitimate next to a containment action on the same
      // stage and illegitimate as the stage's only response, so containment is
      // resolved per stage after the loop.
      final triageOnlyStages = <String>{};
      final containmentStages = <String>{};
      for (final stop in stops) {
        final id = stop.stopId.trim();
        if (id.isEmpty) {
          violations.add('stop_id_blank');
          continue;
        }
        if (!stopIds.add(id)) {
          violations.add('stop_duplicate:$id');
        }
        if (stop.stageId.trim().isEmpty) {
          violations.add('stop_stage_blank:$id');
        } else {
          coveredStages.add(stop.stageId);
          if (anchorStages.isNotEmpty && !anchorStages.contains(stop.stageId)) {
            violations.add('stop_stage_unknown:$id:${stop.stageId}');
          }
        }
        if (anchorMetrics.isNotEmpty &&
            !anchorMetrics.contains(stop.metricId)) {
          violations.add('stop_metric:$id:${stop.metricId}');
        }
        if (!Sprint117CharterContract.knownOperators.contains(stop.operator)) {
          violations.add('stop_operator:$id:${stop.operator}');
        }
        if (stop.windowMinutes <= 0) {
          violations.add('stop_window:$id');
        }
        if (stop.threshold <= 0) {
          violations.add('stop_threshold:$id');
        }
        if (stop.action.trim().isEmpty) {
          violations.add('stop_action:$id');
        } else if (Sprint117CharterContract.containmentActions.contains(
          stop.action,
        )) {
          if (stop.stageId.trim().isNotEmpty) {
            containmentStages.add(stop.stageId);
          }
        } else if (stop.action != 'page_oncall') {
          violations.add('stop_rollback_action:$id:${stop.action}');
        } else if (stop.stageId.trim().isNotEmpty) {
          triageOnlyStages.add(stop.stageId);
        }
        if (stop.killSwitchRef.trim().isEmpty) {
          violations.add('stop_kill_switch:$id');
        }
      }
      // Paging is allowed, but a stage whose only response is a page is a
      // stage the charter promised to stop and never defined how to stop.
      for (final stage in triageOnlyStages) {
        if (!containmentStages.contains(stage)) {
          violations.add('stop_rollback_action:stage:$stage');
        }
      }
      for (final stage in anchorStages) {
        if (!coveredStages.contains(stage)) {
          violations.add('stop_stage_uncovered:$stage');
        }
      }
    }

    // --- ga_criteria -------------------------------------------------------
    final criteria = input.gaCriteria;
    if (criteria == null || criteria.isEmpty) {
      missing.add('ga_criteria');
    } else {
      final criterionIds = <String>{};
      final gates = <String>{};
      for (final criterion in criteria) {
        final id = criterion.criterionId.trim();
        if (id.isEmpty) {
          violations.add('ga_id_blank');
          continue;
        }
        if (!criterionIds.add(id)) {
          violations.add('ga_duplicate:$id');
        }
        if (!Sprint117CharterContract.requiredGaGates.contains(
          criterion.gate,
        )) {
          violations.add('ga_gate:$id:${criterion.gate}');
        } else {
          gates.add(criterion.gate);
        }
        if (criterion.criterion.trim().isEmpty) {
          violations.add('ga_criterion:$id');
        }
        if (!criterion.step.startsWith('117.')) {
          violations.add('ga_step:$id:${criterion.step}');
        }
        if (!criterion.evidenceRequired) {
          violations.add('ga_evidence:$id');
        }
      }
      for (final gate in Sprint117CharterContract.requiredGaGates) {
        if (!gates.contains(gate)) {
          missing.add('ga_criteria');
        }
      }
    }

    // --- carried open items -------------------------------------------------
    // The 117.1 gate reported `release_cut_pending`. A charter that quietly
    // forgets an open item is how it becomes a surprise.
    final carriedIds = _openItemIds(input.carriedOpenItems);
    final anchorOpenItemIds = anchor?.openItemIds ?? const <String>[];
    for (final id in carriedIds) {
      if (anchor != null && !anchorOpenItemIds.contains(id)) {
        violations.add('open_item_invented:$id');
      }
    }
    for (final id in anchorOpenItemIds) {
      if (!carriedIds.contains(id)) {
        violations.add('open_item_dropped:$id');
      }
    }

    final openItems = <String>[...input.carriedOpenItems];

    final fieldCoverage = <String, int>{
      'window': window?.phases.length ?? 0,
      'questions': questions?.length ?? 0,
      'connector_subset': subset?.exposed.length ?? 0,
      'evidence': evidence?.length ?? 0,
      'owners': owners?.length ?? 0,
      'stop_conditions': stops?.length ?? 0,
      'ga_criteria': criteria?.length ?? 0,
    };

    final state = missing.isNotEmpty
        ? Sprint117CharterState.blocked
        : violations.isNotEmpty
        ? Sprint117CharterState.fail
        : Sprint117CharterState.pass;
    final verdict = state == Sprint117CharterState.pass
        ? Sprint117CharterContract.knownVerdicts[0]
        : state == Sprint117CharterState.fail
        ? Sprint117CharterContract.knownVerdicts[2]
        : Sprint117CharterContract.knownVerdicts[1];

    return Sprint117CharterReport(
      state: state,
      verdict: verdict,
      missingFields: missing.toList(growable: false),
      violations: violations,
      window: window,
      questions: questions ?? const <Sprint117CharterQuestion>[],
      connectorSubset: subset,
      evidencePlans: evidence ?? const <Sprint117CharterEvidencePlan>[],
      owners: owners ?? const <Sprint117CharterOwner>[],
      stopConditions: stops ?? const <Sprint117CharterStopCondition>[],
      gaCriteria: criteria ?? const <Sprint117CharterGaCriterion>[],
      anchor: anchor,
      carriedOpenItems: input.carriedOpenItems,
      fieldCoverage: fieldCoverage,
      ownedScopes: ownedScopes.toList(growable: false)..sort(),
      openItems: openItems,
      limitations: const <String>[
        'Charter scope only: this fixes what the beta must answer, over which window, with which evidence, owners, stop conditions, and GA bar. It does not execute any of it.',
        'The window is a plan anchored to the 116.50 rollout stage sequence; no stage has advanced, no flag has been flipped, and no date in this charter has elapsed.',
        'Questions are declared here, but their evidence artifacts do not exist yet by design: the beta has not run, so the answers are DEFERRED-EXTERNAL.',
        'Live cohort recruitment, real consent collection, provider handshakes, a real kill-switch drill, billing settlement, hosted CI, and publication remain DEFERRED-EXTERNAL.',
        'The charter re-derives its anchors from committed Sprint 116 and 117.1 evidence; it never edits those immutable contracts.',
      ],
    );
  }

  List<String> _openItemIds(List<String> items) => <String>[
    for (final item in items)
      item.contains(':') ? item.split(':').first.trim() : item.trim(),
  ];
}
