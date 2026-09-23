/// Staged Rollout Plan (Step 113.41).
///
/// Domain contract for the seven canonical rollout-plan fields —
/// `stage`, `exposure`, `duration`, `health_criteria`, `stop_conditions`,
/// `rollback_owner`, and `approval` — plus evaluation of a staged plan.
///
/// Approval is an explicit state: a plan with a pending approval is
/// structurally complete but not executable, and the evaluation keeps
/// that distinction visible instead of treating "plan written" as
/// "rollout authorized".
library;

/// Canonical required fields, in roadmap order.
const List<String> kStagedRolloutRequiredFields = <String>[
  'stage',
  'exposure',
  'duration',
  'health_criteria',
  'stop_conditions',
  'rollback_owner',
  'approval',
];

/// Evaluation outcome of a staged rollout plan.
enum RolloutPlanState {
  /// Every stage carries all seven fields and approval is explicit.
  pass,

  /// The plan is recorded but structurally incomplete or unapproved.
  fail,

  /// No plan was recorded at all.
  blocked,
}

/// Approval state of one rollout stage.
enum RolloutApproval {
  /// Choirudin explicitly approved this rollout plan.
  approved,

  /// Plan recorded; explicit approval still required before execution.
  pending,

  /// Approval state not recorded.
  unrecorded,
}

/// One staged rollout entry with all seven canonical fields.
class RolloutStage {
  const RolloutStage({
    this.stage,
    this.exposurePercent,
    this.durationHours,
    this.healthCriteria,
    this.stopConditions,
    this.rollbackOwner,
    this.approval,
  });

  final String? stage;
  final int? exposurePercent;
  final double? durationHours;
  final List<String>? healthCriteria;
  final List<String>? stopConditions;
  final String? rollbackOwner;
  final RolloutApproval? approval;

  static bool _nonEmptyList(List<String>? values) =>
      values != null &&
      values.isNotEmpty &&
      values.every((v) => v.trim().isNotEmpty);

  bool get hasRequiredFields =>
      stage != null &&
      stage!.trim().isNotEmpty &&
      exposurePercent != null &&
      exposurePercent! > 0 &&
      exposurePercent! <= 100 &&
      durationHours != null &&
      durationHours! > 0 &&
      _nonEmptyList(healthCriteria) &&
      _nonEmptyList(stopConditions) &&
      rollbackOwner != null &&
      rollbackOwner!.trim().isNotEmpty &&
      approval != null;

  bool get isApproved => approval == RolloutApproval.approved;
}

/// Immutable staged rollout plan.
class StagedRolloutPlan {
  const StagedRolloutPlan({this.stages, this.approvalNotes});

  final List<RolloutStage>? stages;
  final String? approvalNotes;

  /// Returns the canonical names of missing/malformed required fields
  /// aggregated across stages (empty when the plan is structurally sound).
  static List<String> missingFields(StagedRolloutPlan plan) {
    final stages = plan.stages;
    if (stages == null || stages.isEmpty) {
      return List<String>.unmodifiable(kStagedRolloutRequiredFields);
    }
    final missing = <String>[];
    final anyUnapproved = stages.any((s) => s.approval == null);
    for (final stage in stages) {
      if (stage.stage == null || stage.stage!.trim().isEmpty) {
        missing.add('stage');
      }
      if (stage.exposurePercent == null ||
          stage.exposurePercent! <= 0 ||
          stage.exposurePercent! > 100) {
        missing.add('exposure');
      }
      if (stage.durationHours == null || stage.durationHours! <= 0) {
        missing.add('duration');
      }
      if (!_nonEmptyListField(stage.healthCriteria)) {
        missing.add('health_criteria');
      }
      if (!_nonEmptyListField(stage.stopConditions)) {
        missing.add('stop_conditions');
      }
      if (stage.rollbackOwner == null || stage.rollbackOwner!.trim().isEmpty) {
        missing.add('rollback_owner');
      }
      if (stage.approval == null) missing.add('approval');
    }
    if (anyUnapproved) {
      // Field present but not explicitly approved — still missing an
      // *explicit* approval state for execution.
      missing.remove('approval');
      if (!missing.contains('approval_pending')) {
        missing.add('approval_pending');
      }
    }
    return List<String>.unmodifiable(missing.toSet().toList());
  }

  static bool _nonEmptyListField(List<String>? values) =>
      values != null &&
      values.isNotEmpty &&
      values.every((v) => v.trim().isNotEmpty);

  /// Evaluates the plan: null or empty is [RolloutPlanState.blocked];
  /// missing fields fail with the canonical names in notes; a complete
  /// plan whose approval is only pending still FAILS with an explicit
  /// `approval pending` note; only an explicitly approved plan passes,
  /// with stage count, max exposure, and rollback owner in the notes.
  static RolloutPlanEvaluation evaluate(StagedRolloutPlan? plan) {
    if (plan == null || plan.stages == null || plan.stages!.isEmpty) {
      return const RolloutPlanEvaluation(
        state: RolloutPlanState.blocked,
        notes: <String>['no staged rollout plan recorded'],
      );
    }

    final missing = missingFields(plan);
    final structural = missing
        .where((name) => name != 'approval_pending')
        .toList();
    if (structural.isNotEmpty) {
      return RolloutPlanEvaluation(
        state: RolloutPlanState.fail,
        notes: <String>[
          'staged rollout plan incomplete: missing ${structural.join(', ')}',
        ],
      );
    }

    final stages = plan.stages!;
    final unapproved = stages
        .where((s) => s.approval != RolloutApproval.approved)
        .toList();
    if (unapproved.isNotEmpty) {
      return const RolloutPlanEvaluation(
        state: RolloutPlanState.fail,
        notes: <String>[
          'staged rollout plan complete but approval pending — '
              'explicit Choirudin approval required before execution',
        ],
      );
    }

    final maxExposure = stages
        .map((s) => s.exposurePercent!)
        .reduce((a, b) => a > b ? a : b);
    final rollbackOwner = stages.last.rollbackOwner!;
    final totalHours = stages.fold<double>(
      0,
      (sum, s) => sum + s.durationHours!,
    );
    final totalHoursLabel = totalHours == totalHours.truncateToDouble()
        ? totalHours.toInt().toString()
        : totalHours.toString();
    return RolloutPlanEvaluation(
      state: RolloutPlanState.pass,
      notes: <String>[
        'stages: ${stages.length}',
        'max exposure: $maxExposure%',
        'total duration: ${totalHoursLabel}h',
        'rollback owner: $rollbackOwner',
        'approval: approved',
      ],
    );
  }
}

/// Result of evaluating a [StagedRolloutPlan].
class RolloutPlanEvaluation {
  const RolloutPlanEvaluation({required this.state, required this.notes});

  final RolloutPlanState state;
  final List<String> notes;
}
