/// Rollout stage verification contract for Sprint 114.8.
///
/// Dependency-free model that verifies the actual rollout exposure against
/// the approved staged rollout plan (113.41): current stage, exposure within
/// the stage cap, health results, armed stop conditions, a named rollback
/// owner, and an explicit decision. Live rollout execution, telemetry, and
/// publication are external gates and are not claimed here.
enum RolloutStage { notStarted, canaryInternal, broadBeta, gaFull, halted }

enum RolloutDecision {
  noExposure,
  continueExposure,
  reduceExposure,
  haltExposure,
  rollback,
}

enum RolloutStageState { pass, fail, blocked }

class RolloutHealthResult {
  const RolloutHealthResult({required this.name, required this.passed});

  final String name;
  final bool passed;
}

class RolloutStopCondition {
  const RolloutStopCondition({required this.id, required this.triggered});

  final String id;
  final bool triggered;
}

class RolloutStageRecord {
  const RolloutStageRecord({
    required this.currentStage,
    required this.exposurePercent,
    required this.healthResults,
    required this.stopConditions,
    required this.rollbackOwner,
    required this.proposedDecision,
  });

  final RolloutStage currentStage;
  final int exposurePercent;
  final List<RolloutHealthResult> healthResults;
  final List<RolloutStopCondition> stopConditions;
  final String rollbackOwner;
  final RolloutDecision proposedDecision;
}

class RolloutStageReport {
  const RolloutStageReport({
    required this.state,
    required this.currentStage,
    required this.exposure,
    required this.allowedExposurePercent,
    required this.healthResults,
    required this.stopConditions,
    required this.triggeredStopConditions,
    required this.rollbackOwner,
    required this.decision,
    required this.invalidFields,
    required this.violations,
    required this.notes,
  });

  final RolloutStageState state;
  final RolloutStage currentStage;
  final int exposure;
  final int allowedExposurePercent;
  final List<RolloutHealthResult> healthResults;
  final List<RolloutStopCondition> stopConditions;
  final List<String> triggeredStopConditions;
  final String rollbackOwner;
  final RolloutDecision decision;
  final List<String> invalidFields;
  final List<String> violations;
  final List<String> notes;
}

class RolloutStageVerification {
  static const Map<RolloutStage, int> _exposureCaps = <RolloutStage, int>{
    RolloutStage.notStarted: 0,
    RolloutStage.canaryInternal: 5,
    RolloutStage.broadBeta: 50,
    RolloutStage.gaFull: 100,
    RolloutStage.halted: 0,
  };

  RolloutStageReport verify(RolloutStageRecord? record) {
    if (record == null) {
      return const RolloutStageReport(
        state: RolloutStageState.blocked,
        currentStage: RolloutStage.notStarted,
        exposure: 0,
        allowedExposurePercent: 0,
        healthResults: <RolloutHealthResult>[],
        stopConditions: <RolloutStopCondition>[],
        triggeredStopConditions: <String>[],
        rollbackOwner: '',
        decision: RolloutDecision.noExposure,
        invalidFields: <String>[],
        violations: <String>[],
        notes: <String>[
          'Belum ada record rollout; exposure dinilai tidak diklaim; '
              'external rollout execution DEFERRED-EXTERNAL.',
        ],
      );
    }

    final cap = _exposureCaps[record.currentStage]!;
    final invalid = <String>[];
    if (record.exposurePercent < 0 || record.exposurePercent > cap) {
      invalid.add('exposure');
    }
    if (record.rollbackOwner.trim().isEmpty) {
      invalid.add('rollback_owner');
    }
    if (record.stopConditions.isEmpty) {
      invalid.add('stop_conditions');
    }
    final activeStage =
        record.currentStage == RolloutStage.canaryInternal ||
        record.currentStage == RolloutStage.broadBeta ||
        record.currentStage == RolloutStage.gaFull;
    if (activeStage && record.healthResults.isEmpty) {
      invalid.add('health_results');
    }
    if ((record.proposedDecision == RolloutDecision.noExposure &&
            record.exposurePercent > 0) ||
        (record.proposedDecision == RolloutDecision.continueExposure &&
            !activeStage)) {
      invalid.add('decision');
    }

    final healthFailures = record.healthResults
        .where((result) => !result.passed)
        .map((result) => result.name)
        .toList();
    final triggered = record.stopConditions
        .where((condition) => condition.triggered)
        .map((condition) => condition.id)
        .toList();

    final violations = <String>[];
    final unsafeContinue =
        (healthFailures.isNotEmpty || triggered.isNotEmpty) &&
        record.proposedDecision == RolloutDecision.continueExposure;
    if (unsafeContinue) violations.add('stop_condition_ignored');

    return RolloutStageReport(
      state: invalid.isEmpty && violations.isEmpty
          ? RolloutStageState.pass
          : RolloutStageState.fail,
      currentStage: record.currentStage,
      exposure: record.exposurePercent,
      allowedExposurePercent: cap,
      healthResults: List<RolloutHealthResult>.unmodifiable(
        record.healthResults,
      ),
      stopConditions: List<RolloutStopCondition>.unmodifiable(
        record.stopConditions,
      ),
      triggeredStopConditions: List<String>.unmodifiable(triggered),
      rollbackOwner: record.rollbackOwner,
      decision: record.proposedDecision,
      invalidFields: List<String>.unmodifiable(invalid),
      violations: List<String>.unmodifiable(violations),
      notes: const <String>[
        'Verifikasi kontrak lokal terhadap staged rollout plan 113.41; '
            'eksekusi rollout eksternal DEFERRED-EXTERNAL.',
      ],
    );
  }
}
