/// Sprint 103 / 103.28 — performance & resource limits.
///
/// Bounded by design so one runaway workflow can never starve the app:
/// concurrent executions capped, workflow size capped, checkpoint size
/// capped.

library;

class WorkflowLimitExceeded implements Exception {
  WorkflowLimitExceeded(this.message);

  final String message;

  @override
  String toString() => 'WorkflowLimitExceeded: $message';
}

class WorkflowResourceLimits {
  const WorkflowResourceLimits({
    this.maxConcurrentExecutions = 4,
    this.maxStepsPerWorkflow = 64,
    this.maxCheckpointFileBytes = 512 * 1024,
  });

  /// Concurrent workflow executions allowed app-wide (1..8).
  final int maxConcurrentExecutions;

  /// Maximum steps in one workflow definition.
  final int maxStepsPerWorkflow;

  /// Safety net for a single checkpoint JSON file.
  final int maxCheckpointFileBytes;

  void assertWorkflowAllowed(int stepCount) {
    if (stepCount > maxStepsPerWorkflow) {
      throw WorkflowLimitExceeded(
        'workflow has $stepCount steps; limit is $maxStepsPerWorkflow',
      );
    }
  }

  void assertCheckpointSizeAllowed(int bytes) {
    if (bytes > maxCheckpointFileBytes) {
      throw WorkflowLimitExceeded(
        'checkpoint is $bytes bytes; limit is $maxCheckpointFileBytes',
      );
    }
  }
}

/// Tracks live execution slots against [WorkflowResourceLimits].
class WorkflowExecutionSlotTracker {
  WorkflowExecutionSlotTracker({required this.limits});

  final WorkflowResourceLimits limits;
  int _live = 0;

  bool get atCapacity => _live >= limits.maxConcurrentExecutions;

  bool tryAcquire() {
    if (atCapacity) return false;
    _live++;
    return true;
  }

  void release() {
    if (_live > 0) _live--;
  }
}
